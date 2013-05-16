#
# File:       pass_server.rb
#
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
require 'mongo'


include Mongo


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

## AUDIT TYPES
AUDIT_TYPE_TRANS = "transaction"

## SEVERITY TYPES
SEVERITY_TYPE_LOG = "LOG"
SEVERITY_TYPE_ERROR = "ERROR"
SEVERITY_TYPE_FATAL = "FATAL"
SEVERITY_TYPE_WARN = "WARN"

class ApiService < Sinatra::Base


  configure do

    # Setup logger & format
    LOG = Logger.new('log/external_api.log', 'weekly')
    LOG.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime} #{severity}: #{msg}\n"
    end

  end

  configure :development do
    
        config_path = Dir.pwd + "/config/settings_development.yml"
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
        set :memcached_server, config["memcache_servers"]
        
        LOG.debug(config_path)
        LOG.debug(API_SVC_URL)

        begin
            MONGO = MongoClient.new("54.242.195.20", 27017).db("auditlog")
        rescue
            LOG.error("Cannot connect to Mongo") 
            MONGO = nil
        end
        # MONGO1 = MongoClient.new("54.242.195.20", 27017)
        # LOG.info(MONGO1.database_names)
        # MONGO1.database_info.each { |info| LOG.info info.inspect }
        
        LOG.info ("API-Service (Development) launched")
    end

    configure :qa do

        config_path = Dir.pwd + "/config/settings_qa.yml"
        config = YAML::load(File.read(config_path))
        if config  == nil
            LOG.error("Missing settings file!")
            exit
        end
        
        # Set logging level
        LOG.level = Logger::WARN

        # configurations
        API_SVC_URL = config["api_internal_svc_url"]
        DOC_SERVICE_URL = config["api_internal_doc_srv_upld_url"]
        ENV_CLASS = "qa"

        ## cache
        set :memcached_server, config["memcache_servers"]
        
        LOG.debug(config_path)
        LOG.debug(API_SVC_URL)
        
        LOG.info ("API-Service (QA) launched")

    end

    configure :staging do

        config_path = Dir.pwd + "/config/settings_staging.yml"
        config = YAML::load(File.read(config_path))
        if config  == nil
            LOG.error("Missing settings file!")
            exit
        end
        
        # Set logging level
        LOG.level = Logger::ERROR

        # configurations
        API_SVC_URL = config["api_internal_svc_url"]
        DOC_SERVICE_URL = config["api_internal_doc_srv_upld_url"]
        ENV_CLASS = "staging"

        ## cache
        set :memcached_server, config["memcache_servers"]
        
        LOG.debug(config_path)
        LOG.debug(API_SVC_URL)
        
        LOG.info ("API-Service (Staging) launched")

    end

    # initialize the cache
    set :cache, Dalli::Client.new(settings.memcached_server, :expires_in => 3600)
    set :public_folder, 'public'

    # Test route
    get '/' do
        LOG.debug("in base")

        "Welcome to the API service"
    end

    get '/testmongo' do

        auditoptions = {
            :msg => "Test audit request"
        } 

        audit_log(AUDIT_TYPE_TRANS, AUDIT_TYPE_TRANS, auditoptions)

        auditcollection = MONGO.collection("audit_events")

        auditcollection.find.each { |row| LOG.debug row.inspect }

    end

    get '/testcache' do

        originalvalue = settings.cache.get("testvalue1")
        
        unless originalvalue.nil?
            return HTTP_BAD_REQUEST
        end

        settings.cache.set("testvalue", "12346", 20)
        newvalue = settings.cache.get("testvalue")

        if newvalue != "12346"
            return HTTP_BAD_REQUEST
        end

    end
end
