#
# File:       main.rb
#
# Version:    1.0


require 'sinatra/base'
require 'json'
require 'log4r'
require 'rest-client'
require 'cgi'
require 'logger'
require 'color'
require 'yaml'
require 'dalli'
# require 'redcarpet/compat'
require 'rest-client'
require 'mongo_mapper'
require 'require_all'

require_all 'app', 'lib'

# Sinatra's way of splitting up a large project
# include other endpoints
Dir.glob("models/*.rb").each { |r| require_relative "../#{r}" }
Dir.glob("app/api/*.rb").each { |r| require_relative "../#{r}" }

require 'newrelic_rpm'

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
AUDIT_TYPE_OUTSIDE = "outside-call"

## SEVERITY TYPES
SEVERITY_TYPE_LOG = "LOG"
SEVERITY_TYPE_ERROR = "ERROR"
SEVERITY_TYPE_FATAL = "FATAL"
SEVERITY_TYPE_WARN = "WARN" 

class ApiService < Sinatra::Base

  configure do
    set :protection, :except => [:remote_referrer, :json_csrf]
    set :public_folder, 'public'

    # Setup logger and default logging level
    Log4r::StderrOutputter.new('console')
    Log4r::FileOutputter.new('logfile', :filename => 'log/external_api.log', :trunc => false)
    LOG = Log4r::Logger.new('logger')
    LOG.add('console', 'logfile')

    begin
      config_path = Dir.pwd + "/config/settings.yml"
      config = YAML.load(File.open(config_path))[settings.environment.to_s]

      # hc_path = Dir.pwd + "/config/vitals.yml"
      # hc_config = YAML.load(File.open(hc_path))[settings.environment.to_s]
      hc_config = File.open(File.dirname(__FILE__) + "/../config/vitals.yml") { |f| YAML.load(f) }[environment.to_s]

      LOG.debug(config)

        #LOG.debug("1")
        #Dir.glob("/config/initializers/*.rb").each { |init| load init

    rescue
      LOG.error("Missing settings file!") if config == nil
      LOG.error("Missing vitals file!") if hc_config == nil
      exit
    end

    NewRelic::Agent.after_fork(:force_reconnect => true)


    ## config values
    SVC_URLS = config
    API_SVC_URL = config["api_internal_svc_url"]
    MIRTH_SVC_URL = config["mirth_outbound_svc_url"]
    MIRTH_PRIVATE_KEY = config["mirth_private_key"]
    DOC_SERVICE_URL = config["api_internal_doc_srv_upld_url"]
    SOFTWARE_VERSION = config["version"]

    set :enable_auditing, false
    set :api_url, config["api_internal_svc_url"]
    set :memcached_server, config["memcache_servers"]
    set :mongo_server, config["mongo_server"]
    set :dms_server , config["api_internal_doc_srv_upld_url"]
    set :mongo_port, config["mongo_port"]

    set :labs_user, config["lab_user"]
    set :labs_pass, config["lab_pass"]

    set :mirth_edi_token, config["mirth_edi_token"]
    set :mirth_ip, config["mirth_ip_address"]

    # initialize the cache
    set :cache, Dalli::Client.new(settings.memcached_server, :expires_in => 3600)

    # CCAuth
    set :cc_auth_config, File.open(File.dirname(__FILE__) + "/../config/cc_auth_service.yml") { |f| YAML.load(f) }[environment.to_s]
   
    ## setup log level based on yml
    begin
      LOG.level = config["logging_level"]
    rescue => e
      LOG.level = Log4r::ERROR
    end

    ## connect to Mongo
    begin
      set :mongo, {options: {pool_size: 25, pool_timeout: 10, slave_ok: true},
          config: File.open(File.dirname(__FILE__) + "/../config/mongodb.yml") { |f| YAML.load(f) }[environment.to_s]}
    rescue => e
      set :mongo, {options: {pool_size: 25, pool_timeout: 10, slave_ok: true},
          config: {}}
    end

    #temp fix for rspec test
    if settings.environment.to_s != 'test'
      Dir.glob("config/initializers/**/*.rb").each { |init| load init }
      #health check
      HealthCheck.config, HealthCheck.probes_path = hc_config, File.dirname(__FILE__) + "/../probes"
      HealthCheck.start_health_monitor
      CCAuth.configure { |config| config.endpoint = settings.cc_auth_config['url'] }
    end

    LOG.debug("+++++++++++ Loaded External API environment +++++++++++++++")
    LOG.debug(config_path)
    LOG.debug(API_SVC_URL)
    LOG.debug(config)
    LOG.debug(SOFTWARE_VERSION)
  end

  configure :development do
    LOG.info ("API-Service (Development) launched")
  end

  configure :localhost do
    # set :raise_errors, false
    # #  enable :raise_errors
    # set :show_exceptions, false

    LOG.info ("API-Service (Localhost) launched")
  end


  configure :qa do
    LOG.info ("API-Service (QA) launched")
  end

  configure :staging do
    LOG.info ("API-Service (Staging) launched")
  end

  configure :production do
    LOG.info ("API-Service (Production) launched")
  end

  configure :test do
    LOG.info ("API-Service (Test) launched")
    set :enable_auditing, false
  end

  # Establish connection to mongoDB; database as defined in model
  # begin
  #   LOG.debug ("Connecting to MongoMapper at: #{settings.mongo[:config].inspect}")
  #   MongoMapper.setup(settings.mongo[:config], settings.environment, settings.mongo[:options])
  # rescue => e
  #   LOG.error("Connecting to MongoMapper Failed! - #{e.message}")
  #   #    exit if settings.enable_auditing        # Using as a proxy for test environment
  # end



  # Test route
  get '/testmongo' do
    begin
      auditcollection = CareCloud::AuditRecord.first
      LOG.debug('---- Audit Collections ----')
      LOG.debug(auditcollection)
      return 'Mongo is Active'
    rescue
      return 'Error Has Occurred'
    end
  end

  get '/' do
    send_file 'public/index.html'
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

  not_found do

    auditoptions = {
        :ip => "#{request.ip}",
        :request_method => "#{request.request_method}",
        :path => "#{request.fullpath}"
    }

    audit_log(AUDIT_TYPE_TRANS, SEVERITY_TYPE_ERROR, auditoptions)

    LOG.warn 'attempted route that does not exist'
    if response.body.nil? || response.body.first.nil? || !valid_json?(response.body.first)
      %{Sorry, we couldn't find the resource you were looking for.}
    else
      response.body
    end
  end

  error do

    auditoptions = {
        :ip => "#{request.ip}",
        :request_method => "#{request.request_method}",
        :path => "#{request.fullpath}",
        :msg => "#{request.env['sinatra.error'].name} :: #{request.env['sinatra.error'].message}"
    }

    audit_id = audit_log(AUDIT_TYPE_TRANS, SEVERITY_TYPE_FATAL, auditoptions)

    ## TODO: return http error code status(500)

    "Application error. Please try again later. If the issue continues please contact customer support with: #{audit_id}"

  end
  
  APP_API_KEY = 'GtPUILp5Yuz00-r0XSJuh5kuEQ1fT0BM'

end
