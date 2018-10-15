require "active_support"

require "active_median/model"
require "active_median/version"

module ActiveMedian
  def self.drop_function
    ActiveRecord::Base.connection.execute <<-SQL
      DROP AGGREGATE IF EXISTS median(anyelement);
      DROP FUNCTION IF EXISTS median(anyarray);
    SQL
    true
  end
end

ActiveSupport.on_load(:active_record) do
  extend(ActiveMedian::Model)
end
