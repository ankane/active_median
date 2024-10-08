module ActiveMedian
  module Model
    def median(column)
      connection_pool.with_connection do |connection|
        calculate_percentile(column, 0.5, "median", connection)
      end
    end

    def percentile(column, percentile)
      connection_pool.with_connection do |connection|
        calculate_percentile(column, percentile, "percentile", connection)
      end
    end

    private

    def calculate_percentile(column, percentile, operation, connection)
      percentile = Float(percentile, exception: false)
      raise ArgumentError, "invalid percentile" if percentile.nil?
      raise ArgumentError, "percentile is not between 0 and 1" if percentile < 0 || percentile > 1

      # basic version of Active Record disallow_raw_sql!
      # symbol = column (safe), Arel node = SQL (safe), other = untrusted
      # matches table.column and column
      unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral)
        column = column.to_s
        unless /\A\w+(\.\w+)?\z/i.match?(column)
          raise ActiveRecord::UnknownAttributeReference, "Query method called with non-attribute argument(s): #{column.inspect}. Use Arel.sql() for known-safe values."
        end
      end

      column_alias =
        if relation.respond_to?(:column_alias_for, true)
          relation.send(:column_alias_for, "#{operation} #{column.to_s.downcase}")
        else
          # Active Record 7.0.5+
          ActiveRecord::Calculations::ColumnAliasTracker.new(connection).alias_for("#{operation} #{column.to_s.downcase}")
        end
      # safety check
      # could quote, but want to keep consistent with Active Record
      raise "Bad column alias: #{column_alias}. Please report a bug." unless /\A[a-z0-9_]+\z/.match?(column_alias)

      # column resolution
      node = relation.send(:arel_columns, [column]).first
      node = Arel::Nodes::SqlLiteral.new(node) if node.is_a?(String)
      column = connection.visitor.accept(node, Arel::Collectors::SQLString.new).value

      # prevent SQL injection
      percentile = connection.quote(percentile)

      group_values = all.group_values

      # replace select to match behavior of average
      relation = unscope(:select)

      relation =
        case connection.adapter_name
        when /mysql/i, /trilogy/i
          # assume mariadb by default
          # use send as this method is private in Rails 4.2
          mariadb = connection.send(:mariadb?) rescue true

          if mariadb
            if group_values.any?
              over = "PARTITION BY #{group_values.join(", ")}"
            end

            relation.select(*group_values, "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) OVER (#{over}) AS #{column_alias}").unscope(:group)
          else
            # if mysql gets native function, check (and memoize) version first
            relation.select(*group_values, "PERCENTILE_CONT(#{column}, #{percentile}) AS #{column_alias}")
          end
        when /sqlserver/i
          if group_values.any?
            over = "PARTITION BY #{group_values.join(", ")}"
          end

          relation.select(*group_values, "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) OVER (#{over}) AS #{column_alias}").unscope(:group)
        when /sqlite/i
          db = connection.raw_connection
          unless db.instance_variable_get(:@active_median)
            if db.get_first_value("SELECT 1 FROM pragma_function_list WHERE name = 'percentile'").nil?
              require "active_median/sqlite_handler"
              db.create_aggregate_handler(ActiveMedian::SQLiteHandler)
            end
            db.instance_variable_set(:@active_median, true)
          end

          relation.select(*group_values, "PERCENTILE(#{column}, #{percentile} * 100) AS #{column_alias}")
        when /postg/i, /redshift/i # postgis too
          relation.select(*group_values, "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) AS #{column_alias}")
        else
          raise "Connection adapter not supported: #{connection.adapter_name}"
        end

      # same as average
      relation = relation.unscope(:order).distinct!(false) if group_values.empty?

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
