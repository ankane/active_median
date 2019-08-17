require "bundler/setup"
Bundler.require :default
require "minitest/autorun"
require "minitest/pride"
require "logger"

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
