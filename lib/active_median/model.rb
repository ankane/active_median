module ActiveMedian
  module Model
    def median(column)
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

            select(*group_values, "PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY #{column}) OVER (#{over})").unscope(:group)
          else
            # if mysql gets native function, check (and memoize) version first
            select(*group_values, "PERCENTILE_CONT(#{column}, 0.50)")
          end
        when /sqlserver/i
          if group_values.any?
            over = "PARTITION BY #{group_values.join(", ")}"
          end

          select(*group_values, "PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY #{column}) OVER (#{over})").unscope(:group)
        when /sqlite/i
          select(*group_values, "MEDIAN(#{column})")
        when /postg/i, /redshift/i # postgis too
          select(*group_values, "PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY #{column})")
        else
          raise "Connection adapter not supported: #{connection.adapter_name}"
        end

      result = connection.select_all(relation.to_sql)

      # typecast
      rows = []
      columns = result.columns
      result.rows.each do |untyped_row|
        rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] ? result.column_types[c].send(:cast_value, untyped_row[i]) : untyped_row[i] })
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
