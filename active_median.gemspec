require_relative "lib/active_median/version"

Gem::Specification.new do |spec|
  spec.name          = "active_median"
  spec.version       = ActiveMedian::VERSION
  spec.summary       = "Median for Active Record"
  spec.homepage      = "https://github.com/ankane/active_median"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@chartkick.com"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "activerecord", ">= 5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "groupdate"
end
