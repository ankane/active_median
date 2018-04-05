require "active_support"

require "active_median/version"

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

ActiveSupport.on_load(:active_record) do
  require "active_median/patches"
end
