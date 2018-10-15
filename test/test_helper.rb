require "bundler/setup"
Bundler.require :default
require "minitest/autorun"
require "minitest/pride"
require "active_record"
require "groupdate"
require "logger"

adapter = ENV["ADAPTER"] || "postgresql"

def sqlite?
  ENV["ADAPTER"] == "sqlite3"
end

ActiveRecord::Base.establish_connection adapter: adapter, database: sqlite? ? ":memory:" : "active_median_test"
ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["VERBOSE"]

if sqlite?
  db = ActiveRecord::Base.connection.raw_connection
  db.enable_load_extension(1)
  db.load_extension("/tmp/extension-functions.dylib")
  db.enable_load_extension(0)
end

ActiveRecord::Migration.create_table :users, force: true do |t|
  t.integer :visits_count
  t.decimal :latitude, precision: 10, scale: 5
  t.float :rating
  t.string :name
  t.timestamp :created_at
end

ActiveRecord::Migration.create_table :posts, force: true do |t|
  t.references :user
  t.integer :comments_count
end

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
end
