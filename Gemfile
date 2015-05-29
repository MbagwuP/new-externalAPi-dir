source 'http://rubygems.org'
source "http://gem.carecloud.com"

gem 'sinatra', :require => 'sinatra/base'
gem 'require_all'
gem 'color'
gem 'chronic'
gem 'tzinfo'
gem 'redcarpet'
gem 'tilt-jbuilder', '>= 0.4.0', :require => 'sinatra/jbuilder'

# AWS
gem 'care_cloud-storage', '~> 0.0.9'
gem 'care_cloud-queue', '~> 0.0.2'

# cache
gem 'dalli', '~> 2.6'

# logging
gem 'newrelic_rpm', '~> 3.6.3.111'
gem 'log4r'

#requests
gem 'rest-client'
gem 'json'

# mongo
gem 'mongo_mapper'
gem 'bson_ext'

# health check
gem 'health_check', '0.3.3'

gem 'c_cloud_dms_client', path: './vendor/gems'
gem 'c_cloud_http_client', path: './vendor/gems'

gem 'cc_auth'

group :development, :localhost do
  gem 'rack-test'
  gem 'tux'
  gem 'pry'
  gem 'shotgun'
end

group :test do
  gem 'rspec', '~> 2.14'
  gem "rspec_junit_formatter"
end
