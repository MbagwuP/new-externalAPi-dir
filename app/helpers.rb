#
# File:       helpers.rb
#
#
# Version:    1.0

PATIENT_REGEX = '\Apatient-[a-zA-Z0-9._-]{1,75}\z'
PATIENT_MAX_LEN = 75
CASEMGR_REGEX = '\Auser-[a-zA-Z0-9._-]{1,15}\z'
CASEMGR_MAX_LEN = 15
PROVIDER_REGEX = '\Aprovider-[a-zA-Z0-9._-]{1,15}\z'
PROVIDER_MAX_LEN = 15
DATE_REGEX = '\d{8}\z'
DATE_MAX_LEN = 8

class ApiService < Sinatra::Base

  # Convenience method for parsing the authorization token header
  def get_auth_token
    if env && env['HTTP_AUTHORIZATION']
      env['HTTP_AUTHORIZATION'].split(" ").last
    end
  end

  # Convenience method for parsing the authorization token header
  def get_modified_since_tag
    if env && env['HTTP_IF_MODIFIED_SINCE']
      env['HTTP_IF_MODIFIED_SINCE']
    end
  end

  def get_oauth_token
    if request.env['HTTP_AUTHORIZATION']
      CGI.unescape request.env["HTTP_AUTHORIZATION"].gsub('Bearer','').gsub(' ','')
    end
  end

  def escaped_oauth_token
    CGI::escape oauth_token
  end

  def local_timezone?
    params[:local_timezone] && ["true",true,"1",1].include?(params[:local_timezone])
  end

  def oauth_token
    return @oauth_token if defined?(@oauth_token) # caching
    if request.env['HTTP_AUTHORIZATION']
      @oauth_token = CGI.unescape request.env["HTTP_AUTHORIZATION"].gsub('Bearer','').gsub(' ','')
    else
      api_svc_halt HTTP_NOT_AUTHORIZED, '{"error": "Access token is required"}'
    end
    @oauth_token
  end

  def base_url
    # @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    @base_url ||= "https://#{request.env['HTTP_HOST']}"
  end

  # http://mentalized.net/journal/2011/04/14/ruby_how_to_check_if_a_string_is_numeric/
  def is_this_numeric(param)
    Float(param) != nil rescue false
  end

  # Convenience method to validate parameters length and content
  def validate_param(param, regex, max)
    begin
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing parameter"}' if param == nil
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Parameter length > than permitted"}' if param.length > max
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Parameter has invalid characters"}' if param.match(regex) == nil
    rescue => e
      LOG.error("Validating parameters - #{e.message}")
      api_svc_halt HTTP_INTERNAL_ERROR, '{"error":"INTERNAL ERROR - problem validating param"}'
    end
  end

  # Generate a URI for a Webservices call - query_params can be a hash or a string
  def webservices_uri path, query_params=nil
    uri = URI.parse(API_SVC_URL + path)
    uri.query = query_params.is_a?(Hash) ? query_params.to_query : query_params
    uri.to_s
  end

  # Convenience method for retrieving the JSON body
  def get_request_JSON
    if request && request.body
      request.body.rewind
      begin
        request_body = request.body.read
        request_body.gsub!(':null', ':""') # JSON.parse errors if a value of null is provided, even though null is valid JSON
        request_json = JSON.parse(request_body)
      rescue
        api_svc_halt HTTP_BAD_REQUEST, '{"error":"JSON input is not valid, try www.JSONlint.com"}'
      end
    end
  end

  ## get the business entity id based on the token from the cache
  ## this data exists on the authenticated user, but if we cannot find it in cache, we need a place to go
  ## hence the secondary call
  def get_business_entity(pass_in_token)

    ## TODO: figure this encoding out
    pass_in_token = CGI::unescape(pass_in_token)
    #LOG.debug("passed in token: " + pass_in_token)

    ## HACK: Special logic for mirth
    if pass_in_token == settings.mirth_edi_token
      return process_backdoor_business_entity(pass_in_token)
    else

      ## check cache for business entity by token
      cache_key = "business-entity-" + pass_in_token

      #LOG.debug("cache key: " + cache_key)

      begin
        returned_business_entity_id = settings.cache.get(cache_key)
      rescue => e
        returned_business_entity_id = ""
        LOG.warn("cannot reach cache store")
      end

      if returned_business_entity_id.nil? || returned_business_entity_id == ""

        #LOG.debug("business entity not found in cache, making the call")

        ## make webservice call to get business entitites by user
        urlbusentitylist = ''
        urlbusentitylist << API_SVC_URL
        urlbusentitylist << 'business_entities/list_by_user.json?list_type=list&token='
        urlbusentitylist << CGI::escape(pass_in_token)

        #LOG.debug("url for business entity list: " + urlbusentitylist)

        begin
          resp = RestClient.get(urlbusentitylist)
        rescue => e
          begin
            errmsg = "Get Business Entity Failed - #{e.message}"
            api_svc_halt e.http_code, errmsg
          rescue
            api_svc_halt HTTP_INTERNAL_ERROR, errmsg
          end
        end

        ## validate business entity passed in is in list
        parsed = JSON.parse(resp.body)["business_entities"]

        api_svc_halt HTTP_BAD_REQUEST, '{"error":"User is assigned to more then one business entity"}' if parsed.length > 1

        returned_business_entity_id = parsed[0]["id"]
        #LOG.debug("returned business entity id: " + returned_business_entity_id.to_s)

        ## cache the result
        begin
          settings.cache.set(cache_key, returned_business_entity_id.to_s, 500000)
            #LOG.debug("++++++++++cache set")
        rescue => e
          LOG.warn("cannot reach cache store")
        end

      end

      return returned_business_entity_id.to_s

    end

  end

  def current_session
    return @current_session if defined?(@current_session) # caching
    begin
      CCAuth::OAuth2Client.new.authorization(oauth_token)
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
  end

  def current_business_entity
    return @current_business_entity if defined?(@current_business_entity) # caching
    cache_key = "business-entity-guid-" + oauth_token

    begin
      @current_business_entity = settings.cache.fetch(cache_key, 54000) do
        current_session[:business_entity_id].to_s
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @current_business_entity = current_session[:business_entity_id].to_s
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @current_business_entity
  end

  def current_application
    return @current_application if defined?(@current_application) # caching
    cache_key = "application-" + oauth_token

    begin
      @current_application = settings.cache.fetch(cache_key, 54000) do
        current_session[:application][:id]
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @current_application = current_session[:application][:id]
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @current_application
  end

  def get_providers_by_business_entity(business_entity_id, pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)
    returned_provider_object = ""

    ## check cache for business entity by token
    cache_key = "business-entity-" + business_entity_id + "-providers-" + pass_in_token

    #LOG.debug("cache key: " + cache_key)

    begin
      returned_providers_by_business_entity = settings.cache.get(cache_key)
    rescue => e
      returned_providers_by_business_entity = ""
      LOG.warn("cannot reach cache store")
    end

    if returned_providers_by_business_entity.nil? || returned_providers_by_business_entity == ""

      #LOG.debug("providers for business entity not found in cache, making the call")

      #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
      urlprovider = ''
      urlprovider << API_SVC_URL
      urlprovider << 'public/businesses/'
      urlprovider << business_entity_id
      urlprovider << '/providers.json?token='
      urlprovider << CGI::escape(pass_in_token)

      #LOG.debug("url for providers: " + urlprovider)


      begin
        resp = RestClient.get(urlprovider)
      rescue => e
        begin
          errmsg = "Get Provider List Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end


      returned_providers_by_business_entity = resp.body
      #LOG.debug(returned_provider_object)

      ## cache the result
      begin
        settings.cache.set(cache_key, returned_providers_by_business_entity.to_s, 500000)
          #LOG.debug("++++++++++cache set")
      rescue => e
        LOG.warn("cannot reach cache store")
      end

    end

    return JSON.parse(returned_providers_by_business_entity)

  end

  def check_for_valid_provider (provider_list, provider_id)

    begin
      invalid_provider = true
      provider_list['providers'].each { |x|

        if x['id'].to_s == provider_id.to_s
          invalid_provider = false
          break
        end
      }

      if invalid_provider
        api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
      end

    rescue
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
    end
  end

  def validate_icd_indicator indicator_value
    if indicator_value.blank?
      indicator_value = 9
    elsif ![9, 10].include? indicator_value.to_i
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"icd_indicator must be \'9\' or \'10\'"}'
    end
    indicator_value.to_i
  end

  def get_internal_patient_id (patientid, business_entity_id, pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)

    if !is_this_numeric(patientid)

      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity_id
      urlpatient << '/patients/'
      urlpatient << patientid
      urlpatient << '/externalid.json?token='
      urlpatient << CGI::escape(pass_in_token)

      #LOG.debug("url for patient: " + urlpatient)

      begin
        resp = RestClient.get(urlpatient)
      rescue => e
        begin
          errmsg = "Get Patient Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      parsed = JSON.parse(resp.body)

      patientid = parsed["patient"]["id"].to_s

      #LOG.debug(patientid)

    end

    return patientid

  end

  def get_internal_patient_id_by_patient_number (patientid, business_entity_id, pass_in_token)

      pass_in_token = CGI::unescape(pass_in_token)
      urlpatient = "#{API_SVC_URL}businesses/#{business_entity_id}/patients/#{patientid}/othermeans.json?token=#{CGI::escape(pass_in_token)}"

      begin
        resp = RestClient.get(urlpatient)
      rescue => e
        begin
          errmsg = "Get Patient Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      parsed = JSON.parse(resp.body)
      patientid = parsed["patient"]["id"].to_s
      return patientid
  end

  def get_patient_id_with_other_id (id, business_entity_id, pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity_id
    urlpatient << '/patients/'
    urlpatient << id
    urlpatient << '/othermeans.json?token='
    urlpatient << CGI::escape(pass_in_token)

    #LOG.debug("url for patient: " + urlpatient)

    begin
      resp = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Get patient id with other id Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(resp.body)

    patientid = parsed["patient"]["id"].to_s

    #LOG.debug(patientid)


    return patientid

  end

  def get_appointment_internal_id (id, business_entity_id, pass_in_token)

    pass_in_token = pass_in_token
    appointmentid = id
    business_entity = business_entity_id
    #http://devservices.carecloud.local/appointments/1/abcd93832/listbyexternalid.json?token=
    urlappt = "#{API_SVC_URL}appointments/#{business_entity}/#{appointmentid}/listbyexternalid.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body).first
    return parsed["appointment"]["id"]
  end

  ## use AUDIT_TYPE and AUDIT_SEVERITY
  def audit_log(type, severity, options={})
    return if !settings.enable_auditing
    begin
      audit_entry = CareCloud::AuditRecord.create(:type => type,
                                                  :severity => severity,
                                                  :ip_address => options[:ip],
                                                  :statuscode => options[:statuscode],
                                                  :duration => options[:duration],
                                                  :request_method => options[:request_method],
                                                  :msg => options[:msg],
                                                  :request_path => options[:request_path],
                                                  :request_body => options[:request_body],
                                                  :response_body => options[:response_body])
    rescue Exception => e
      err_msg = {}
      err_msg["error"] = "Audit log failed! - #{e.message}"
      LOG.error(err_msg)
      return
      # Don't think this should cause the API call to fail
      # api_svc_halt HTTP_INTERNAL_ERROR, err_msg.to_json
    end

    LOG.debug "Audit Entry UUID:#{audit_entry._id} Type:#{audit_entry.type} IP:#{audit_entry.ip_address} Created:#{audit_entry.created_at} Updated:#{audit_entry.updated_at}"

  end


  def create_batch_error(options)
    return if !settings.enable_auditing
    begin
      batch_error = CareCloud::BatchErrors.create(:statuscode => options[:status_code],
                                                  :is_reprocess => options[:is_reprocess],
                                                  :request_method => options[:request_method],
                                                  :busines_entity_id => options[:busines_entity_id],
                                                  :error_msg => options[:error_msg],
                                                  :response_body => options[:response_body],
                                                  :error_code => options[:error_code],
                                                  :response_body => options[:response_body])
    rescue Exception => e
      err_msg = {}
      err_msg["error"] = "Batch Error Failed! - #{e.message}"
      LOG.error(err_msg)
      return
      # Don't think this should cause the API call to fail
      # api_svc_halt HTTP_INTERNAL_ERROR, err_msg.to_json
    end

    LOG.debug "Audit Entry UUID:#{batch_error._id} Type:#{batch_error.type} Business_entity:#{batch_error.ip_address} Created:#{batch_error.created_at} Updated:#{batch_error.updated_at}"

  end

  def api_svc_halt(statuscode, message="{}")
    # There is a bug in Sinatra in that repsonse.status is not set prior to after filter being called when a "halt" occurs
    # This just caches the value and then halts
    @statuscode = statuscode
    @message = message
    message = wrap_message_as_json(message_keyname, message) if !valid_json?(message)

    halt statuscode, message
  end

  def handle_exception(exception)
    LOG.error(exception)
    api_svc_halt HTTP_INTERNAL_ERROR, '{"error":"An error occured we cannot recover from. If this continues please contact support."}'
  end

  def rescue_service_call call_description, expose_ws_error=false
    begin
      yield
    rescue => e
      begin
        error_detail = if expose_ws_error
                         ws_error = JSON.parse(e.http_body)['error']['message'] rescue nil
                         ws_error || e.message
                       else
                         e.message
                       end
        error_msg = "#{call_description} Failed - #{error_detail}"
        api_svc_halt e.http_code, error_msg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, error_msg
      end
    end
  end

  def valid_json?(str)
    return false if !str.is_a?(String)
    begin
      !JSON.parse(str).nil?
    rescue JSON::ParserError
      false
    end
  end

  def message_keyname(statuscode=nil)
    statuscode = @statuscode if defined?(@statuscode)
    !statuscode.nil? && statuscode >= 400 ? 'error' : 'message'
  end

  def wrap_message_as_json(message_keyname, message)
    {message_keyname => message}.to_json
  end

  def get_all_business_entities(pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)

    ## check cache for business entity by token
    cache_key = "business-entity-" + pass_in_token

    begin
      returned_business_entity_ids = settings.cache.get(cache_key)
    rescue => e
      returned_business_entity_ids = nil
      LOG.error("Cache error - #{e.message}")
    end

    if returned_business_entity_ids.nil? || returned_business_entity_ids == ""

      ## make webservice call to get business entitites by user
      begin
        response = RestClient.get("#{settings.core_api_service_url}/business_entities/list_by_user.json?list_type=list&token=#{CGI::escape(pass_in_token)}")
      rescue => e
        LOG.warn("Retrieving Business Entities by token Failed - #{e.message}")
        return nil
      end

      parsed = JSON.parse(response.body)["business_entities"]

      ## Extract business entities
      returned_business_entity_ids = ''
      parsed.each do |entity|
        returned_business_entity_ids << entity["id"].to_s
        returned_business_entity_ids << ','
      end

      ## cache the result
      begin
        settings.cache.set(cache_key, returned_business_entity_ids.to_s, 500000)
      rescue => e
        LOG.error("Cache error - #{e.message}")
      end

    end

    return returned_business_entity_ids.to_s

  end

  def check_for_valid_business_entity (entity_id, pass_in_token)
    entity_list = get_all_business_entities(pass_in_token)

    return false if entity_list.nil?

    return entity_list.include? entity_id.to_s
  end

  def error_handler_filter(e)
    error_string = ''
    begin
      errors = JSON.parse(e.response.body) if e.response.body.length < 300
      return 'Internal Server Error' if errors['error']['error_code'] == 500
      if errors['error']['details'].is_a? Array
        errors['error']['details'].each do |exc|
          error_string << exc['message'] + ','
        end
      elsif !errors['error'].nil?
        error_string = errors['error']['message'] if errors['error']['details'].nil?
      else
        error_string = e.message
      end
    rescue
      error_string = e.message
      error_string = "An error has occurred, Please contact a CareCloud specialist" if e.message.blank?
    end
    error_string
  end

  def process_backdoor_business_entity (pass_in_token)

    patientid = params[:patientid]
    patientid.slice!(/^patient-/)

    ## check IP addresses
    ipaddress = request.ip
    #LOG.debug(ipaddress)
    # api_svc_halt HTTP_FORBIDDEN if !settings.mirth_ip.include? ipaddress

    ## call for BE by patient

    ## check cache for business entity by token
    cache_key = "business-entity-patient-" + patientid

    #LOG.debug("cache key: " + cache_key)

    begin
      returned_business_entity_id = settings.cache.get(cache_key)
    rescue => e
      returned_business_entity_id = ""
      LOG.warn("cannot reach cache store")
    end

    if returned_business_entity_id.nil? || returned_business_entity_id == ""

      #LOG.debug("business entity not found in cache, making the call")

      ## make webservice call to get business entitites by user
      urlbusentitylist = ''
      urlbusentitylist << API_SVC_URL
      urlbusentitylist << 'business_entities/list_by_patient/'
      urlbusentitylist <<  patientid
      urlbusentitylist << '.json?token='
      urlbusentitylist << CGI::escape(pass_in_token)

      #LOG.debug("url for business entity list: " + urlbusentitylist)

      begin
        resp = RestClient.get(urlbusentitylist)
      rescue => e
        begin
          errmsg = "Get backdoor BE Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end


      ## validate business entity passed in is in list
      parsed = JSON.parse(resp.body)

      returned_business_entity_id = parsed[0]["patient"]["business_entity_id"]
      #LOG.debug("returned business entity id: " + returned_business_entity_id.to_s)

      ## cache the result
      begin
        settings.cache.set(cache_key, returned_business_entity_id.to_s, 500000)
          #LOG.debug("++++++++++cache set")
      rescue => e
        LOG.warn("cannot reach cache store")
      end

    end


    ## return BE
    return returned_business_entity_id.to_s()

  end

  def authenticate_mirth_request(id, key)
    # key determination
    current_date = DateTime.now()

    mirth_key = ''
    mirth_key << MIRTH_PRIVATE_KEY
    mirth_key << current_date.strftime('%Y%m%d')
    mirth_key << id

    h = Digest::SHA2.new << mirth_key
    if key != h.to_s

      audit_options = {
          :ip => "#{request.ip}",
          :msg => 'Invalid request for inbound lab. Unauthorized user'
      }

      audit_log(AUDIT_TYPE_TRANS, AUDIT_TYPE_TRANS, audit_options)

      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid request sent"}'
    end

  end


  def recall_statuses
    return @recall_statuses if defined?(@recall_statuses) # caching
    cache_key = "recall-statuses"

    begin
      @recall_statuses = settings.cache.fetch(cache_key, 54000) do
        recall_statuses_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @recall_statuses = recall_statuses_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @recall_statuses
  end

  def recall_statuses_from_webservices
    urlcm = webservices_uri "recall_statuses/list_all.json"

    resp = rescue_service_call 'Recall Status Look Up' do
      request = RestClient::Request.new(url: urlcm, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |rs|
      key = rs['recall_status']['name'].underscore.gsub(' ', '_')
      val = rs['recall_status']['id']
      output[key] = val #if filter_here?
    end
    output
  end


  def communication_methods
    return @communication_methods if defined?(@communication_methods) # caching
    cache_key = "communication-methods"

    begin
      @communication_methods = settings.cache.fetch(cache_key, 54000) do
        communication_methods_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @communication_methods = communication_methods_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @communication_methods
  end

  def visible_communication_method? communication_method_slug
    ['phone','email','text_message','fax','other','none'].include? communication_method_slug
  end

  def communication_methods_from_webservices
    urlcm = webservices_uri "communication_methods/list_all.json"

    resp = rescue_service_call 'Communication Method Look Up' do
      request = RestClient::Request.new(url: urlcm, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |cm|
      key = cm['communication_method']['name'].underscore.gsub(' ', '_')
      val = cm['communication_method']['id']
      output[key] = val if visible_communication_method?(key)
    end
    output
  end


  def communication_outcomes
    return @communication_outcomes if defined?(@communication_outcomes) # caching
    cache_key = "communication-outcomes"

    begin
      @communication_outcomes = settings.cache.fetch(cache_key, 54000) do
        communication_outcomes_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @communication_outcomes = communication_outcomes_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @communication_outcomes
  end

  def communication_outcomes_from_webservices
    urlco = webservices_uri "communication_outcomes/list_all.json"

    resp = rescue_service_call 'Communication Outcome Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['communication_outcome']['name'].underscore.gsub(' ', '_')
      val = co['communication_outcome']['id']
      output[key] = val
    end
    output
  end

  def debit_transaction_types
    return @debit_transaction_types if defined?(@debit_transaction_types) # caching
    cache_key = "debit-transaction-types"

    begin
      @debit_transaction_types = settings.cache.fetch(cache_key, 54000) do
        debit_transaction_types_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @debit_transaction_types = debit_transaction_types_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @debit_transaction_types
  end

  def debit_transaction_types_from_webservices
    urlco = webservices_uri "debit_transactions/types/list_all.json"

    resp = rescue_service_call 'Debit Transaction Type Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['debit_transaction_type']['name'].underscore.gsub(' ', '_')
      val = co['debit_transaction_type']['id']
      output[key] = val
    end
    output
  end

  def credit_transaction_types
    return @credit_transaction_types if defined?(@credit_transaction_types) # caching
    cache_key = "credit-transaction-types"

    begin
      @credit_transaction_types = settings.cache.fetch(cache_key, 54000) do
        credit_transaction_types_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @credit_transaction_types = credit_transaction_types_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @credit_transaction_types
  end

  def credit_transaction_types_from_webservices
    urlco = webservices_uri "credit_transactions/types/list_all.json"

    resp = rescue_service_call 'Credit Transaction Type Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['credit_transaction_type']['name'].underscore.gsub(' ', '_')
      val = co['credit_transaction_type']['id']
      output[key] = val
    end
    output
  end

  def transaction_statuses
    return @transaction_statuses if defined?(@transaction_statuses) # caching
    cache_key = "transaction-statuses"

    begin
      @transaction_statuses = settings.cache.fetch(cache_key, 54000) do
        transaction_statuses_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @transaction_statuses = transaction_statuses_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @transaction_statuses
  end

  def transaction_statuses_from_webservices
    urlco = webservices_uri "transactions/statuses/list_all.json"

    resp = rescue_service_call 'Transaction Status Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['transaction_status']['name'].underscore.gsub(' ', '_')
      val = co['transaction_status']['id']
      output[key] = val
    end
    output
  end

  def oauth_request?
    token = request.env['HTTP_AUTHORIZATION']
    token && !token.include?('Basic') && token.length < 40
  end

end