require "active_median/version"
require "active_record"

module ActiveMedian
  def self.create_function
    # create median method
    # http://www.postgresonline.com/journal/archives/67-Build-Median-Aggregate-Function-in-SQL.html
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE OR REPLACE FUNCTION array_median(numeric[])
        RETURNS numeric AS
      $$
        SELECT CASE
          WHEN array_upper($1, 1) = 0 THEN null
          WHEN mod(array_upper($1, 1), 2) = 1 THEN asorted[ceiling(array_upper(asorted, 1) / 2.0)]
          ELSE (
            (
              asorted[ceiling(array_upper(asorted, 1) / 2.0)] +
              asorted[ceiling(array_upper(asorted, 1) / 2.0) + 1]
            ) / 2.0
          )
          END
        FROM (
          SELECT ARRAY(
            SELECT ($1)[n] FROM generate_series(1, array_upper($1, 1)) AS n
            WHERE ($1)[n] IS NOT NULL ORDER BY ($1)[n]
          ) AS asorted
        ) AS foo;
      $$
        LANGUAGE SQL;

      DROP AGGREGATE IF EXISTS median(numeric);
      CREATE AGGREGATE median(numeric) (
        SFUNC=array_append,
        STYPE=numeric[],
        FINALFUNC=array_median
      );
    SQL
    true
  end
end

module ActiveRecord
  module Calculations
    def median(column_name, options = {})
      calculate(:median, column_name, options)
    end
  end
end

module ActiveRecord
  module Querying
    delegate :median, :to => (Gem::Version.new(Arel::VERSION) >= Gem::Version.new("4.0.1") ? :all : :scoped)
  end
end

module Arel
  module Nodes
    const_set("Median", Class.new(Function))
  end
end

module Arel
  module Expressions
    def median
      Nodes::Median.new [self], Nodes::SqlLiteral.new('median_id')
    end
  end
end

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Nodes_Median o, a=nil
        if a
          "AVG(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map { |x|
          visit x, a }.join(', ')})#{o.alias ? " AS #{visit o.alias, a}" : ''}"
        else
          "MEDIAN(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map { |x|
          visit x }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
        end
      end
    end
  end
end

module Arel
  module Visitors
    class DepthFirst
      alias :visit_Arel_Nodes_Median :function
    end
  end
end

module Arel
  module Visitors
    class Dot
      alias :visit_Arel_Nodes_Median :function
    end
  end
end
