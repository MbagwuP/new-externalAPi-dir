ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require 'sinatra'

require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)
require_all 'app'

require File.join(File.dirname(__FILE__), '..', 'app/main.rb')

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  ApiService
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.color = true
end
