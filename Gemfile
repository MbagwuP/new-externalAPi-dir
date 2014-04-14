source 'http://rubygems.org'

gem 'sinatra', :require => 'sinatra/base'
gem 'require_all'
gem 'color'

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
#gem 'health_check', git: 'git@github.com:CareCloud/health_check.git'
gem 'health_check', path: './vendor/bundle'
gem 'c_cloud_dms_client', path: './vendor/bundle'
gem 'c_cloud_http_client', path: './vendor/bundle'

#authentication
# gem 'cc_auth', git: 'git@github.com:CareCloud/auth_gem.git'

group :test, :development, :localhost do
  gem 'rspec'
  gem 'rack-test'
end
