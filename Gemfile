source 'http://rubygems.org'
source "http://gem.carecloud.com"

gem 'sinatra', :require => 'sinatra/base'
gem 'require_all'
gem 'color'
gem 'chronic'
gem 'tzinfo'
gem 'tilt-jbuilder', '>= 0.4.0', :require => 'sinatra/jbuilder'

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

gem 'c_cloud_dms_client', path: './vendor/bundle'
gem 'c_cloud_http_client', path: './vendor/bundle'

gem 'cc_auth'

group :test, :development, :localhost do
  gem 'rspec', '~> 2.14'
  gem 'rack-test'
  gem 'tux'
  gem 'pry'
  gem 'shotgun'
end
