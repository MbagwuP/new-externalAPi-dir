ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'sinatra'

require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)
require_all 'app'

INTERFACE_USER = 'interface2@interface.com'
INTERFACE_PASS = 'Welcome1['


require File.join(File.dirname(__FILE__), '..', 'app/main.rb')

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  ApiService
end


module Helpers

  def stub_memcached
    cache = Dalli::Client.new('localhost:999', :expires_in => 3600)
    app.stub(:cache) { cache }
    app.cache.stub(:fetch) { nil }
    app.cache.stub(:set) {|key,value| value }
  end

end


RSpec.configure do |config|
  config.include Helpers
  config.include Rack::Test::Methods
  config.color = true
end
