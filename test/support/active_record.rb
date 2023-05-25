require "active_record"
require "groupdate"

if adapter == "sqlserver"
  # https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver16
  ActiveRecord::Base.establish_connection "sqlserver://SA:YourStrong!Passw0rd@localhost:1433/active_median_test"
elsif adapter == "redshift"
  ActiveRecord::Base.establish_connection ENV["DATABASE_URL"]
else
  ActiveRecord::Base.establish_connection adapter: adapter, database: sqlite? ? ":memory:" : "active_median_test"
end

ActiveRecord::Base.logger = $logger
ActiveRecord::Migration.verbose = ENV["VERBOSE"]

ext = RbConfig::CONFIG["host_os"] =~ /darwin/i ? "dylib" : "so"
if sqlite? && File.exist?("/tmp/percentile.#{ext}")
  db = ActiveRecord::Base.connection.raw_connection
  db.enable_load_extension(1)
  db.load_extension("/tmp/percentile.#{ext}")
  db.enable_load_extension(0)
end

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.integer :visits_count
    t.decimal :latitude, precision: 10, scale: 5
    t.float :rating
    t.string :name
    t.datetime :created_at
  end

  create_table :posts, force: true do |t|
    t.references :user
    t.integer :comments_count
  end
end

class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
end
