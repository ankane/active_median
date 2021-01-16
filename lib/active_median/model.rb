module ActiveMedian
  module Model
    def median(column)
      percentile(column, 0.5)
    end

    def percentile(column, percentile)
      percentile = percentile.to_f
      raise ArgumentError, "percentile is not between 0 and 1" if percentile < 0 || percentile > 1

      # basic version of Active Record disallow_raw_sql!
      # symbol = column (safe), Arel node = SQL (safe), other = untrusted
      # matches table.column and column
      unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral) || /\A\w+(\.\w+)?\z/i.match(column.to_s)
        warn "[active_median] Non-attribute argument: #{column}. Use Arel.sql() for known-safe values. This will raise an error in ActiveMedian 0.3.0"
      end

      # column resolution
      node = relation.send(:arel_columns, [column]).first
      node = Arel::Nodes::SqlLiteral.new(node) if node.is_a?(String)
      column = relation.connection.visitor.accept(node, Arel::Collectors::SQLString.new).value

      # prevent SQL injection
      percentile = connection.quote(percentile)

      group_values = all.group_values

      relation =
        case connection.adapter_name
        when /mysql/i
          # assume mariadb by default
          # use send as this method is private in Rails 4.2
          mariadb = connection.send(:mariadb?) rescue true

          if mariadb
            if group_values.any?
              over = "PARTITION BY #{group_values.join(", ")}"
            end

            select(*group_values, "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) OVER (#{over})").unscope(:group)
          else
            # if mysql gets native function, check (and memoize) version first
            select(*group_values, "PERCENTILE_CONT(#{column}, #{percentile})")
          end
        when /sqlserver/i
          if group_values.any?
            over = "PARTITION BY #{group_values.join(", ")}"
          end

          select(*group_values, "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) OVER (#{over})").unscope(:group)
        when /sqlite/i
          case percentile.to_f
          when 0
            select(*group_values, "MIN(#{column})")
          when 0.5
            select(*group_values, "MEDIAN(#{column})")
          when 1
            select(*group_values, "MAX(#{column})")
          else
            # LOWER_QUARTILE and UPPER_QUARTILE use different calculation than 0.25 and 0.75
            raise "SQLite only supports 0, 0.5, and 1 percentiles"
          end
        when /postg/i, /redshift/i # postgis too
          select(*group_values, "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column})")
        else
          raise "Connection adapter not supported: #{connection.adapter_name}"
        end

      # same as average
      relation = relation.unscope(:order).distinct!(false) if relation.group_values.empty?

      result = connection.select_all(relation.to_sql)

      # typecast
      rows = []
      columns = result.columns
      result.rows.each do |untyped_row|
        rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] && result.column_types[c] ? result.column_types[c].send(:cast_value, untyped_row[i]) : untyped_row[i] })
      end

      result =
        if group_values.any?
          Hash[rows.map { |r| [r.size == 2 ? r[0] : r[0..-2], r[-1]] }]
        else
          rows[0] && rows[0][0]
        end

      result = Groupdate.process_result(relation, result) if defined?(Groupdate.process_result)

      result
    end
  end
end
