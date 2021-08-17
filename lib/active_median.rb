require "active_support"

require "active_median/enumerable"
require "active_median/version"

module ActiveMedian
  # TODO remove in 0.4.0
  def self.drop_function
    ActiveRecord::Base.connection.execute <<-SQL
      DROP AGGREGATE IF EXISTS median(anyelement);
      DROP FUNCTION IF EXISTS median(anyarray);
    SQL
    true
  end
end

ActiveSupport.on_load(:active_record) do
  require "active_median/model"
  extend(ActiveMedian::Model)
end

ActiveSupport.on_load(:mongoid) do
  require "active_median/mongoid"
  Mongoid::Document::ClassMethods.include(ActiveMedian::Mongoid)
end
