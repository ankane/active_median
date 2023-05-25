# dependencies
require "active_support"

# modules
require_relative "active_median/enumerable"
require_relative "active_median/version"

ActiveSupport.on_load(:active_record) do
  require_relative "active_median/model"
  extend(ActiveMedian::Model)
end

ActiveSupport.on_load(:mongoid) do
  require_relative "active_median/mongoid"
  Mongoid::Document::ClassMethods.include(ActiveMedian::Mongoid)
end
