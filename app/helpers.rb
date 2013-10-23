#
# File:       helers.rb
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

  # Convenience method to map responses back from called WS to values defined in application
  # HTTP_OK = 200
  # HTTP_CREATED = 201
  # HTTP_NO_CONTENT = 204
  # HTTP_NOT_MODIFIED = 304
  # HTTP_BAD_REQUEST = 400
  # HTTP_NOT_AUTHORIZED = 401
  # HTTP_NOT_FOUND = 404
  # HTTP_CONFLICT = 409
  # HTTP_INTERNAL_ERROR = 500
  def map_response(response_code)

    case response_code
      when "200"
        return HTTP_OK
      when "201"
        return HTTP_CREATED
      when "204"
        return HTTP_NO_CONTENT
      when "304"
        return HTTP_NOT_MODIFIED
      when "400"
        return HTTP_BAD_REQUEST
      when "401"
        return HTTP_NOT_AUTHORIZED
      when "403"
        return HTTP_FORBIDDEN
      when "404"
        return HTTP_NOT_FOUND
      when "409"
        return HTTP_CONFLICT
      else
        return HTTP_INTERNAL_ERROR
    end
  end

  # convenience routine to POST, PUT or GET a http request
  def generate_http_request (target_url, authorization_hdr, body, method="POST", username=nil, password=nil, abortonfail=true)
    begin
      uri = URI.parse(target_url)
      http = Net::HTTP.new(uri.host, uri.port)
      # Great option to help with the debugging
      #http.set_debug_output $stderr

      #if https url, set the secure flags
      if target_url.index(/\Ahttps/)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      if method == "POST"
        request = Net::HTTP::Post.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        request.body = body
      elsif method == "PUT"
        request = Net::HTTP::Put.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        request.body = body
      elsif method == "DELETE"
        request = Net::HTTP::Delete.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        request.body = body
      elsif method == "GET"
        request = Net::HTTP::Get.new(uri.request_uri)
      else
        # Whoops :)
        return nil
      end

      if authorization_hdr != ""
        request["Authorization"] = authorization_hdr
      end

      if username != nil && password != nil
        request.basic_auth username, password
      end

      response = http.request(request)

      if response.code.to_i != HTTP_OK
        LOG.warn("#{method} #{target_url} Response code: #{response.code} Response msg: #{response.message}")
      end

      return response

    rescue => e
      LOG.error("#{method} #{target_url} FAILED - #{e.message}")
      if abortonfail
        api_svc_halt HTTP_INTERNAL_ERROR, '{"error":"Internal error while calling method. Please try again later"}'
      else
        return nil
      end

    end
  end


  ## get the business entity id based on the token from the cache
  ## this data exists on the authenticated user, but if we cannot find it in cache, we need a place to go
  ## hence the secondary call
  def get_business_entity(pass_in_token)

    ## TODO: figure this encoding out
    pass_in_token = CGI::unescape(pass_in_token)
    LOG.debug("passed in token: " + pass_in_token)

    ## HACK: Special logic for mirth
    if pass_in_token == settings.mirth_edi_token
      return process_backdoor_business_entity(pass_in_token)
    else

      ## check cache for business entity by token
      cache_key = "business-entity-" + pass_in_token

      LOG.debug("cache key: " + cache_key)

      begin
        returned_business_entity_id = settings.cache.get(cache_key)
      rescue => e
        returned_business_entity_id = ""
        LOG.error("cannot reach cache store")
      end

      if returned_business_entity_id.nil? || returned_business_entity_id == ""

        LOG.debug("business entity not found in cache, making the call")

        ## make webservice call to get business entitites by user
        urlbusentitylist = ''
        urlbusentitylist << API_SVC_URL
        urlbusentitylist << 'business_entities/list_by_user.json?list_type=list&token='
        urlbusentitylist << CGI::escape(pass_in_token)

        LOG.debug("url for business entity list: " + urlbusentitylist)

        resp = generate_http_request(urlbusentitylist, "", "", "GET")

        LOG.debug(resp.body)

        response_code = map_response(resp.code.to_s)

        if response_code == HTTP_OK

          ## validate business entity passed in is in list
          parsed = JSON.parse(resp.body)["business_entities"]

          api_svc_halt HTTP_BAD_REQUEST, '{"error":"User is assigned to more then one business entity"}' if parsed.length > 1

          returned_business_entity_id = parsed[0]["id"]
          LOG.debug("returned business entity id: " + returned_business_entity_id.to_s)

          ## cache the result
          begin
            settings.cache.set(cache_key, returned_business_entity_id.to_s, 500000)
            LOG.debug("++++++++++cache set")
          rescue => e
            LOG.error("cannot reach cache store")
          end
        elsif response_code == HTTP_FORBIDDEN
          api_svc_halt HTTP_FORBIDDEN, resp.body
        else
          api_svc_halt HTTP_INTERNAL_ERROR, resp.body
        end
      end

      return returned_business_entity_id.to_s

    end

  end

  def get_providers_by_business_entity(business_entity_id, pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)
    returned_provider_object = ""

    ## check cache for business entity by token
    cache_key = "business-entity-" + business_entity_id + "-providers-" + pass_in_token

    LOG.debug("cache key: " + cache_key)

    begin
      returned_providers_by_business_entity = settings.cache.get(cache_key)
    rescue => e
      returned_providers_by_business_entity = ""
      LOG.error("cannot reach cache store")
    end

    if returned_providers_by_business_entity.nil? || returned_providers_by_business_entity == ""

      LOG.debug("providers for business entity not found in cache, making the call")

      #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
      urlprovider = ''
      urlprovider << API_SVC_URL
      urlprovider << 'public/businesses/'
      urlprovider << business_entity_id
      urlprovider << '/providers.json?token='
      urlprovider << CGI::escape(pass_in_token)

      LOG.debug("url for providers: " + urlprovider)

      resp = generate_http_request(urlprovider, "", "", "GET")

      returned_providers_by_business_entity = resp.body
      LOG.debug(returned_provider_object)

      ## cache the result
      begin
        settings.cache.set(cache_key, returned_providers_by_business_entity.to_s, 500000)
        LOG.debug("++++++++++cache set")
      rescue => e
        LOG.error("cannot reach cache store")
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

      LOG.debug("url for patient: " + urlpatient)

      resp = generate_http_request(urlpatient, "", "", "GET")

      LOG.debug(resp.body)

      response_code = map_response(resp.code)
      if response_code == HTTP_OK

        parsed = JSON.parse(resp.body)

        patientid = parsed["patient"]["id"].to_s

        LOG.debug(patientid)

      else
        api_svc_halt HTTP_BAD_REQUEST, '{"error":"Cannot locate patient record"}'
      end

    end

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

    LOG.debug("url for patient: " + urlpatient)

    resp = generate_http_request(urlpatient, "", "", "GET")

    LOG.debug(resp.body)

    response_code = map_response(resp.code)
    if response_code == HTTP_OK

      parsed = JSON.parse(resp.body)

      patientid = parsed["patient"]["id"].to_s

      LOG.debug(patientid)

    else
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Cannot locate patient record"}'
    end

    return patientid

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

    auditoptions = {
        :ip => "#{request.ip}",
        :status => "#{statuscode}",
        :duration => "#{request_duration} ms",
        :request_method => "#{request.request_method}",
        :requestbody => "#{request.body.read}",
        :responsebody => "#{response.body.to_s}",
        :path => "#{request.fullpath}"
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

    ## get the audit collection
    begin
      unless settings.mongo.nil?
        auditcollection = settings.mongo.collection("audit_events")

        insertdocument = {
            "type" => "#{type}",
            "severity" => "#{severity}",
            "ip_address" => "#{options[:ip]}",
            "status" => "#{options[:status]}",
            "duration" => "#{options[:duration]}",
            "request_method" => "#{options[:request_method]}",
            "request_path" => "#{options[:path]}",
            "msg" => "#{options[:msg]}",
            "request_body" => "#{options[:requestbody]}",
            "response_body" => "#{options[:responsebody]}",
            "timestamp" => "#{Time.now}"

        }

        mongo_id = auditcollection.insert(insertdocument)

        LOG.debug("++mongo inserted: " + insertdocument.to_json)

        return mongo_id
      end

    rescue => e
      LOG.error("cannot reach mongo store")
    end

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


  def process_backdoor_business_entity (pass_in_token)

    patientid = params[:patientid]
    patientid.slice!(/^patient-/)

    ## check IP addresses
    ipaddress = request.ip
    LOG.debug(ipaddress)
    api_svc_halt HTTP_FORBIDDEN if !settings.mirth_ip.include? ipaddress

    ## call for BE by patient

    ## check cache for business entity by token
    cache_key = "business-entity-patient-" + patientid

    LOG.debug("cache key: " + cache_key)

    begin
      returned_business_entity_id = settings.cache.get(cache_key)
    rescue => e
      returned_business_entity_id = ""
      LOG.error("cannot reach cache store")
    end

    if returned_business_entity_id.nil? || returned_business_entity_id == ""

      LOG.debug("business entity not found in cache, making the call")

      ## make webservice call to get business entitites by user
      urlbusentitylist = ''
      urlbusentitylist << API_SVC_URL
      urlbusentitylist << 'business_entities/list_by_patient/'
      urlbusentitylist <<  patientid
      urlbusentitylist << '.json?token='
      urlbusentitylist << CGI::escape(pass_in_token)

      LOG.debug("url for business entity list: " + urlbusentitylist)

      resp = generate_http_request(urlbusentitylist, "", "", "GET")

      LOG.debug(resp.body)

      response_code = map_response(resp.code.to_s)

      if response_code == HTTP_OK

        ## validate business entity passed in is in list
        parsed = JSON.parse(resp.body)

        returned_business_entity_id = parsed[0]["patient"]["business_entity_id"]
        LOG.debug("returned business entity id: " + returned_business_entity_id.to_s)

        ## cache the result
        begin
          settings.cache.set(cache_key, returned_business_entity_id.to_s, 500000)
          LOG.debug("++++++++++cache set")
        rescue => e
          LOG.error("cannot reach cache store")
        end
      elsif response_code == HTTP_FORBIDDEN
        api_svc_halt HTTP_FORBIDDEN, resp.body
      else
        api_svc_halt HTTP_INTERNAL_ERROR, resp.body
      end
    end


    ## return BE
    return returned_business_entity_id.to_s()

  end



end