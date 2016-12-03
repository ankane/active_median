require "active_median/version"
require "active_record"

module ActiveMedian
  def self.create_function
    # create median method
    # http://wiki.postgresql.org/wiki/Aggregate_Median
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE OR REPLACE FUNCTION median(anyarray)
         RETURNS float8 AS
      $$
        WITH q AS
        (
           SELECT val
           FROM unnest($1) val
           WHERE VAL IS NOT NULL
           ORDER BY 1
        ),
        cnt AS
        (
          SELECT COUNT(*) AS c FROM q
        )
        SELECT AVG(val)::float8
        FROM
        (
          SELECT val FROM q
          LIMIT  2 - MOD((SELECT c FROM cnt), 2)
          OFFSET GREATEST(CEIL((SELECT c FROM cnt) / 2.0) - 1,0)
        ) q2;
      $$
      LANGUAGE sql IMMUTABLE;

      DROP AGGREGATE IF EXISTS median(numeric);
      DROP AGGREGATE IF EXISTS median(double precision);
      DROP AGGREGATE IF EXISTS median(anyelement);
      CREATE AGGREGATE median(anyelement) (
        SFUNC=array_append,
        STYPE=anyarray,
        FINALFUNC=median,
        INITCOND='{}'
      );
    SQL
    true
  end

  def self.drop_function
    ActiveRecord::Base.connection.execute <<-SQL
      DROP AGGREGATE IF EXISTS median(anyelement);
      DROP FUNCTION IF EXISTS median(anyarray);
    SQL
    true
  end
end

module ActiveRecord
  module Calculations
    def median(*args)
      calculate(:median, *args)
    end
  end
end

module ActiveRecord
  module Querying
    delegate :median, to: (Gem::Version.new(Arel::VERSION) >= Gem::Version.new("4.0.1") ? :all : :scoped)
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
      Nodes::Median.new [self], Nodes::SqlLiteral.new("median_id")
    end
  end
end

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Nodes_Median(o, a = nil)
        if Gem::Version.new(Arel::VERSION) >= Gem::Version.new("6.0.0")
          aggregate "MEDIAN", o, a
        elsif a
          "MEDIAN(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map do |x|
            visit x, a
          end.join(', ')})#{o.alias ? " AS #{visit o.alias, a}" : ''}"
        else
          "MEDIAN(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map do |x|
            visit x
          end.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
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
