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

  def oauth_token
    return @oauth_token if defined?(@oauth_token) # caching
    if request.env['HTTP_AUTHORIZATION']
      @oauth_token = CGI.unescape request.env["HTTP_AUTHORIZATION"].gsub('Bearer','').gsub(' ','')
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

  def current_business_entity
    return @current_business_entity if defined?(@current_business_entity) # caching
    cache_key = "business-entity-guid-" + oauth_token

    begin
      @current_business_entity = settings.cache.fetch(cache_key) do
        session = CCAuth::OAuth2.new.authorization(oauth_token)
        business_entity = session[:business_entity_id].to_s

        settings.cache.set(cache_key, business_entity, 500000)

        business_entity
      end
    rescue => e
      LOG.warn("cannot reach cache store")
    end
    @current_business_entity
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

  # Control the level of logging based on settings
  before do
    content_type 'application/json', :charset => 'utf-8'
    @start_time = Time.now

    auditoptions = {
        :ip => "#{request.ip}",
        :request_method => "#{request.request_method}",
        :path => "#{request.fullpath}"
    }

    audit_log(AUDIT_TYPE_TRANS, SEVERITY_TYPE_LOG, auditoptions)

  end

  after do
    request_duration = ((Time.now - @start_time) * 1000.0).to_i
    statuscode = @statuscode || response.status

    ## todo: get who the user is
    auditoptions = {
        :ip => "#{request.ip}",
        :statuscode => "#{statuscode}",
        :duration => "#{request_duration} ms",
        :request_method => "#{request.request_method}",
        :request_path => "#{request.fullpath}"
    }

    audit_log(AUDIT_TYPE_TRANS, SEVERITY_TYPE_LOG, auditoptions)

    if statuscode >= HTTP_BAD_REQUEST
      LOG.warn("----#{request.ip} \"#{request.request_method} #{request.fullpath}\" - #{statuscode} #{@message} - #{request_duration} ms")
    else
      LOG.info("----#{request.ip} \"#{request.request_method} #{request.fullpath}\" - #{statuscode} #{@message} - #{request_duration} ms")
    end
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

    halt statuscode, message
  end

  def handle_exception(exception)
    LOG.error(exception)
    api_svc_halt HTTP_INTERNAL_ERROR, '{"error":"An error occured we cannot recover from. If this continues please contact support."}'
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
    #api_svc_halt HTTP_FORBIDDEN if !settings.mirth_ip.include? ipaddress

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



end