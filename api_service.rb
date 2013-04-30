#
# File:       pass_server.rb
#
# TODO
#  newrelic
#  test cases
#  amazon
#  cleanup
#  apigee
#  wrapper to return 500 on all cases exception
# Version:    1.0

require 'sinatra/base'
require 'json'
require 'socket'
require 'net/https'
require 'net/http'
require 'uri'
require 'logger'
require 'color'
require 'yaml'
require 'dalli'


# Sinatra's way of splitting up a large project
# include other endpoints
Dir.glob("models/*.rb").each { |r| require_relative r }
Dir.glob("app/*.rb").each { |r| require_relative r }

# Define http response codes
HTTP_OK = 200
HTTP_CREATED = 201
HTTP_NO_CONTENT = 204
HTTP_NOT_MODIFIED = 304
HTTP_BAD_REQUEST = 400
HTTP_NOT_AUTHORIZED = 401
HTTP_FORBIDDEN = 403
HTTP_NOT_FOUND = 404
HTTP_CONFLICT = 409
HTTP_INTERNAL_ERROR = 500

class ApiService < Sinatra::Base

  configure :development do
    
        # Setup logger & format
        LOG = Logger.new(STDOUT)
        LOG.formatter = proc do |severity, datetime, progname, msg|
            "#{datetime} #{severity}: #{msg}\n"
        end
   
        config_path = Dir.pwd + "/config/settings.yml"
        config = YAML::load(File.read(config_path))
        if config  == nil
            LOG.error("Missing settings file!")
            exit
        end
        
        # Set logging level
        LOG.level = Logger::DEBUG

        # configurations
        API_SVC_URL = config["api_internal_svc_url"]
        DOC_SERVICE_URL = config["api_internal_doc_srv_upld_url"]
        ENV_CLASS = "dev"

        ## cache
        cahcelocation = config["memcache_servers"]
        CACHESTORE = Dalli::Client.new(cahcelocation,
                                        :expires_in => 20)
        

        LOG.debug(config_path)
        LOG.debug(API_SVC_URL)
        
        LOG.info ("API-Service launched")
    end

    # Test route
    get '/' do
        LOG.debug("in base")

        "Welcome to the API service"
    end

    get '/testcache' do

        originalvalue = CACHESTORE.get("testvalue1")
        
        unless originalvalue.nil?
            return HTTP_BAD_REQUEST
        end

        CACHESTORE.set("testvalue", "12346", 20)
        newvalue = CACHESTORE.get("testvalue")

        if newvalue != "12346"
            return HTTP_BAD_REQUEST
        end

    end
end
