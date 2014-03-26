# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'c_cloud_web_services/version'

Gem::Specification.new do |spec|
  spec.name          = "c_cloud_web_services"
  spec.version       = CCloudWebServices::VERSION
  spec.authors       = ["“Peter"]
  spec.email         = ["“Plee@carecloud.com”"]
  spec.description   = %q{A description about careclouds webservice}
  spec.summary       = %q{A description about careclouds webservice}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
