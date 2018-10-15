require "bundler/setup"
Bundler.require :default
require "minitest/autorun"
require "minitest/pride"
require "active_record"
require "logger"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "active_median_test"

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["VERBOSE"]

ActiveRecord::Migration.create_table :users, force: true do |t|
  t.integer :visits_count
  t.decimal :latitude
  t.float :rating
  t.string :name
end

class User < ActiveRecord::Base
end
