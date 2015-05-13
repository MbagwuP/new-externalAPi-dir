require 'rubygems'

# auto discover your Gemfile, and make all of the gems in your Gemfile available to Ruby (i.e put the gems "on the load path"). 
# You can think of it as an adding some extra powers to require 'rubygems'
require 'bundler/setup'

# require all gems from Gemfile (:default namespace)
Bundler.require(:default)

require './app/main'

use HealthCheck::Middleware, description: {service: "External API", description: "External API Service", version: ApiService.build_version}
APP_ROOT = File.expand_path('.', File.dirname(__FILE__)) unless defined? APP_ROOT

run ApiService

