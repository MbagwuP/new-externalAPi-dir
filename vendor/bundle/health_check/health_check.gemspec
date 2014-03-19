# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'health_check/version'

Gem::Specification.new do |spec|
  spec.name          = "health_check"
  spec.version       = HealthCheck::VERSION
  spec.authors       = ["David Salazar"]
  spec.email         = ["dsalazar@carecloud.com"]
  spec.summary       = %q{Health check service}
  spec.description   = %q{Health check service}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
