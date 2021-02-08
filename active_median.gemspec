require_relative "lib/active_median/version"

Gem::Specification.new do |spec|
  spec.name          = "active_median"
  spec.version       = ActiveMedian::VERSION
  spec.summary       = "Median and percentile for Active Record, Mongoid, arrays, and hashes"
  spec.homepage      = "https://github.com/ankane/active_median"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "activesupport", ">= 5.2"
end
