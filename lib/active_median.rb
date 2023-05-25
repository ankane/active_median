require "active_support"

require "active_median/enumerable"
require "active_median/version"

ActiveSupport.on_load(:active_record) do
  require "active_median/model"
  extend(ActiveMedian::Model)
end

ActiveSupport.on_load(:mongoid) do
  require "active_median/mongoid"
  Mongoid::Document::ClassMethods.include(ActiveMedian::Mongoid)
end
