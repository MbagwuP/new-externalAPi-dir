source "http://gem.carecloud.com"
source 'http://rubygems.org'

gem 'sinatra', :require => 'sinatra/base'
gem 'require_all'
gem 'color'
gem 'chronic'
gem 'tzinfo'
gem 'tilt-jbuilder', '>= 0.4.0', :require => 'sinatra/jbuilder'
gem 'oj', '~> 2.10.0'

# AWS
gem 'care_cloud-storage', '~> 0.0.9'
gem 'care_cloud-queue', '~> 0.0.2'

# cache
gem 'dalli-elasticache', '~> 0.2.0'

# logging
gem 'newrelic_rpm', '~> 3.12.0.288'
gem 'log4r'

#requests
gem 'rest-client'
gem 'json'

# mongo
gem 'mongo_mapper'
gem 'bson_ext'

# health check
gem 'health_check', '0.3.3'#, :source => 'http://gem.carecloud.com/'

gem 'c_cloud_dms_client', path: './vendor/gems'
gem 'c_cloud_http_client', path: './vendor/gems'

gem 'cc_auth', '~> 0.8.0'

gem 'rake'
gem 'dotenv'

group :development, :localhost, :test do
  gem 'rack-test'
  gem 'tux'
  gem 'pry'
  gem 'pry-byebug'
  gem 'shotgun'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'awesome_print'
end

group :test do
  gem 'rspec', '~> 2.14'
  gem "rspec_junit_formatter"
end
