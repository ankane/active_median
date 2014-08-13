require "bundler/setup"
Bundler.require :default
require "minitest/autorun"
require "minitest/pride"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "active_median_test"

ActiveRecord::Migration.create_table :users, force: true do |t|
  t.integer :visits_count
  t.decimal :latitude
  t.float :rating
end

class User < ActiveRecord::Base
end
