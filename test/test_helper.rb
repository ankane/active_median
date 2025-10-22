require "bundler/setup"
Bundler.require :default
require "minitest/autorun"

$logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)

def adapter
  ENV["ADAPTER"] || "postgresql"
end

def sqlite?
  adapter == "sqlite3"
end

def mongoid?
  defined?(Mongoid)
end

if mongoid?
  require_relative "support/mongoid"
else
  require_relative "support/active_record"
end

if ActiveSupport::VERSION::STRING.to_f >= 8.0
  ActiveSupport.to_time_preserves_timezone = :zone
elsif ActiveSupport::VERSION::STRING.to_f == 7.2
  ActiveSupport.to_time_preserves_timezone = true
end
