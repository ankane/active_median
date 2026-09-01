module ActiveMedian
  module Model
    def median(column)
      connection_pool.with_connection do |connection|
        calculate_percentiles(connection, "median", column, 0.5)
      end
    end

    def percentile(column, *percentiles)
      connection_pool.with_connection do |connection|
        calculate_percentiles(connection, "percentile", column, *percentiles)
      end
    end
    alias_method :percentiles, :percentile

    private

    def calculate_percentiles(connection, operation, column, *percentiles)
      percentiles.map do |percentile|
        Float(percentile, exception: false).tap do |p|
          raise ArgumentError, "invalid percentile" if p.nil?
          raise ArgumentError, "percentile is not between 0 and 1" if p < 0 || p > 1
        end
      end

      # basic version of Active Record disallow_raw_sql!
      # symbol = column (safe), Arel node = SQL (safe), other = untrusted
      # matches table.column and column
      unless column.is_a?(Symbol) || column.is_a?(Arel::Nodes::SqlLiteral)
        column = column.to_s
        unless /\A\w+(\.\w+)?\z/i.match?(column)
          raise ActiveRecord::UnknownAttributeReference, "Query method called with non-attribute argument(s): #{column.inspect}. Use Arel.sql() for known-safe values."
        end
      end

      column_aliases = percentiles.map do |p|
        alias_base = percentiles.one? ? "#{operation} #{column.to_s.downcase}" : "#{operation}_#{p.to_s.gsub(".", "_")}_#{column.to_s.downcase}"

        column_alias =
          if relation.respond_to?(:column_alias_for, true)
            relation.send(:column_alias_for, alias_base)
          else
            # Active Record 7.0.5+
            ActiveRecord::Calculations::ColumnAliasTracker.new(connection).alias_for(alias_base)
          end
        # safety check
        # could quote, but want to keep consistent with Active Record
        raise "Bad column alias: #{column_alias}. Please report a bug." unless /\A[a-z0-9_]+\z/.match?(column_alias)
        column_alias
      end

      # column resolution
      node = relation.send(:arel_columns, [column]).first
      node = Arel::Nodes::SqlLiteral.new(node) if node.is_a?(String)
      column = connection.visitor.accept(node, Arel::Collectors::SQLString.new).value

      # prevent SQL injection
      percentiles = percentiles.map { |percentile| connection.quote(percentile) }

      group_values = all.group_values

      # replace select to match behavior of average
      relation = unscope(:select)

      select_expressions = percentiles.zip(column_aliases).map do |percentile, column_alias|
        case connection.adapter_name
        when /mysql/i, /trilogy/i
          # assume mariadb by default
          # use send as this method is private in Rails 4.2
          mariadb = connection.send(:mariadb?) rescue true

          if mariadb
            if group_values.any?
              over = "PARTITION BY #{group_values.join(", ")}"
            end
            "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) OVER (#{over}) AS #{column_alias}"
          else
            # if mysql gets native function, check (and memoize) version first
            "PERCENTILE_CONT(#{column}, #{percentile}) AS #{column_alias}"
          end
        when /sqlserver/i
          if group_values.any?
            over = "PARTITION BY #{group_values.join(", ")}"
          end
          "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) OVER (#{over}) AS #{column_alias}"
        when /sqlite/i
          "PERCENTILE(#{column}, #{percentile} * 100) AS #{column_alias}"
        when /postg/i, /redshift/i # postgis too
          "PERCENTILE_CONT(#{percentile}) WITHIN GROUP (ORDER BY #{column}) AS #{column_alias}"
        else
          raise "Connection adapter not supported: #{connection.adapter_name}"
        end
      end

      # this block was moved out of the case statement above so it's executed once
      if connection.adapter_name =~ /sqlite/i
        db = connection.raw_connection
        unless db.instance_variable_get(:@active_median)
          if db.get_first_value("SELECT 1 FROM pragma_function_list WHERE name = 'percentile'").nil?
            require "active_median/sqlite_handler"
            db.create_aggregate_handler(ActiveMedian::SQLiteHandler)
          end
          db.instance_variable_set(:@active_median, true)
        end
      end

      relation = relation.select(*group_values, *select_expressions)

      # this unscope was done in the block above for these db adapters
      if (connection.adapter_name =~ /mysql|trilogy|sqlserver/i) && group_values.any?
        relation = relation.unscope(:group)
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
          if percentiles.one?
            # for grouped queries with a single percentile, maintain the existing behavior
            Hash[rows.map { |r| [r.size == 2 ? r[0] : r[0..-2], r[-1]] }]
          else
            # for grouped queries with multiple percentiles, return a hash with group keys and arrays of percentile values
            Hash[rows.map { |r|
              group_key = r.size == (percentiles.size + 1) ? r[0] : r[0..-(percentiles.size + 1)]
              percentile_values = r[-percentiles.size..-1]
              [group_key, percentile_values]
            }]
          end
        else
          if percentiles.one?
            # for non-grouped queries with a single percentile, maintain the existing behavior
            rows[0] && rows[0][0]
          else
            # for non-grouped queries with multiple percentiles, return an array of values or nil if no data
            if rows[0] && rows[0].any? { |v| !v.nil? }
              rows[0]
            else
              nil
            end
          end
        end

      result = Groupdate.process_result(relation, result) if defined?(Groupdate.process_result)

      result
    end
  end
end
