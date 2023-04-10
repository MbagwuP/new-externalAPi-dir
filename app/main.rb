#
# File:       main.rb
#
# Version:    1.0

# Dotenv
# support loading environment specific override files (ex. .env.localhost)
# load the base/global .env file last.  sequence matters.  vars set in previously loaded .env.<env> files take precedence.
rack_env = (ENV['RACK_ENV'] || 'development')
envs = []
envs << ".env.#{rack_env}" if %{localhost}.include?(rack_env)
envs << ".env"
Dotenv.load(*envs)

require 'sinatra/base'
require 'json'
require 'log4r'
require 'rest-client'
require 'cgi'
require 'logger'
require 'color'
require 'yaml'
require 'dalli'
require 'rest-client'
require 'mongo_mapper'
require 'require_all'
require 'pry'

require_all 'app', 'lib'

# Sinatra's way of splitting up a large project
# include other endpoints
Dir.glob("models/*.rb").each { |r| require_relative "../#{r}" }
Dir.glob("modules/*.rb").each { |r| require_relative "../#{r}" }
Dir.glob("app/api/*.rb").each { |r| require_relative "../#{r}" }

require 'newrelic_rpm'

APP_ROOT = File.expand_path('..', File.dirname(__FILE__)) unless defined? APP_ROOT

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
HTTP_UNPROCESSABLE_ENTITY = 422
HTTP_INTERNAL_ERROR = 500
HTTP_SERVICE_UNAVAILABLE = 503

## AUDIT TYPES
AUDIT_TYPE_TRANS = "transaction"
AUDIT_TYPE_OUTSIDE = "outside-call"

## SEVERITY TYPES
SEVERITY_TYPE_LOG = "LOG"
SEVERITY_TYPE_ERROR = "ERROR"
SEVERITY_TYPE_FATAL = "FATAL"
SEVERITY_TYPE_WARN = "WARN"

USE_AMAZON_API_GATEWAY = true

class ApiService < Sinatra::Base

  register Sinatra::ApplicationFilters
  register Sinatra::V2::Clinical::Payers
  register Sinatra::V2::Clinical::Payers::Plans
  register Sinatra::V2::Clinical::Payers::Policies
  register Sinatra::V2::Clinical::Forms
  register Sinatra::V2::Clinical::FormTemplates
  register Sinatra::V2::Clinical::FormTemplates::Configs
  register Sinatra::V2::Drugs
  register Sinatra::V2::Allergens
  register Sinatra::V2::AllergenTypes
  register Sinatra::V2::Practices::FeatureSubscription

  def self.build_version
    build_number = File.open(File.expand_path("../../.build", __FILE__), 'rb').read rescue ''
    build_number = build_number.split(':')[1] unless build_number.empty?
    build_number.strip
  end
  
  use HealthCheck::Middleware, description: { service: "External API", description: "External API Service", build: ApiService.build_version, commit: `git rev-parse --verify --short HEAD`.strip }

  configure do
    set :protection, :except => [:remote_referrer, :json_csrf]
    set :public_folder, 'public'

    # Setup logger and default logging level
    Log4r::StderrOutputter.new('console')
    Log4r::FileOutputter.new('logfile', :filename => 'log/external_api.log', :trunc => false)
    LOG = Log4r::Logger.new('logger')
    LOG.add('console', 'logfile')

    Oj.default_options = {mode: :compat}

    begin
      config_path = File.expand_path("../../config/settings.yml", __FILE__)
      config = YAML.load(ERB.new(File.read(config_path)).result)[environment.to_s]
      hc_config = YAML.load(File.open(File.expand_path("../../config/vitals.yml", __FILE__)))
      LOG.debug(config)
    rescue 
      LOG.error("Missing settings file!") if config == nil
      LOG.error("Missing vitals file!") if hc_config == nil
      exit
    end

    NewRelic::Agent.after_fork(:force_reconnect => true)

    Aws.config = { region:'us-east-1' }

    ## config values
    SVC_URLS = config
    API_SVC_URL = config["api_internal_svc_url"]
    MIRTH_SVC_URL = config["mirth_outbound_svc_url"]
    MIRTH_PRIVATE_KEY = config["mirth_private_key"]
    DOC_SERVICE_URL = config["api_internal_doc_srv_upld_url"]
    SOFTWARE_VERSION = config["version"]
    CLINICAL_DATA_API = config["clinical_data_api"]
    ENABLE_FDB = config["enable_fdb"]

    set :enable_auditing, false
    set :api_url, config["api_internal_svc_url"]
    set :platform_url, config["platform_url"]
    set :memcached_servers, config["memcache_servers"]
    set :mongo_server, config["mongo_server"]
    set :dms_server , config["api_internal_doc_srv_upld_url"]
    set :mongo_port, config["mongo_port"]

    set :labs_user, config["lab_user"]
    set :labs_pass, config["lab_pass"]

    set :mirth_edi_token, config["mirth_edi_token"]
    set :mirth_ip, config["mirth_ip_address"]

    # CCAuth
    set :cc_auth_config, YAML.load(ERB.new(File.read(File.expand_path("../../config/cc_auth_service.yml", __FILE__))).result)[settings.environment.to_s]

    ## setup log level based on yml
    begin
      LOG.level = config["logging_level"]
    rescue => e
      LOG.level = Log4r::ERROR
    end

    ## connect to Mongo
    begin
      set :mongo, {options: {pool_size: 25, pool_timeout: 10, slave_ok: true},
          config: File.open(File.dirname(__FILE__) + "/../config/mongodb.yml") { |f| YAML.load(f)[settings.environment.to_s] } }
    rescue => e
      set :mongo, {options: {pool_size: 25, pool_timeout: 10, slave_ok: true},
          config: {}}
    end

    #temp fix for rspec test
    if settings.environment.to_s != 'test'
      Dir.glob("config/initializers/**/*.rb").each { |init| load init }
      HealthCheck.config      = hc_config 
      HealthCheck.probes_path = File.dirname(__FILE__) + "/../probes"
      HealthCheck.start_health_monitor
    end

    CCAuth.configure do |config|
      config.endpoint         = settings.cc_auth_config['url']
      config.internal_api_key = settings.cc_auth_config['internal_api_key']
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

    originalvalue = XAPI::Cache.get("testvalue1")

    unless originalvalue.nil?
      return HTTP_BAD_REQUEST
    end

    XAPI::Cache.set("testvalue", "12346", 20)
    newvalue = XAPI::Cache.get("testvalue")

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
