ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', 'app/main.rb')

require 'test/unit'
require 'rack/test'
require 'sinatra'

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
