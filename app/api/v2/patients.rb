class ApiService < Sinatra::Base

  post '/v2/patients/search?' do
    ## Validate the input parameters
    request_body = get_request_JSON

    #TODO: Build search_limit and search_data variables smarter then whats there
    search_data = ""
    request_body['search'].each { |x|
      search_data = search_data + x["term"] + " "
      #LOG.debug(search_data)
    }

    search_limit = request_body['limit'].to_s
    #TODO: add external id to patient search
    #TODO: replace id with external id

    #business_entity_patient_search        /businesses/:business_entity_id/patients/search.:format  {:controller=>"patients", :action=>"search_by_business_entity"}
    #http://localservices.carecloud.local:3000/businesses/1/patients/search.json?token=<token>&search=test%20smith&limit=50
    #/businesses/:business_entity_id/patients/search.:format
    urlpatient = webservices_uri "businesses/#{current_business_entity}/patients/search.json",
                                 {token: escaped_oauth_token, limit: search_limit, search: search_data}

    response = rescue_service_call 'Search' do
      RestClient.get(urlpatient)
    end

    returnedBody = JSON.parse(response.body)
    returnedBody["patients"].each {|x| x["id"] = x["external_id"]}
    body(returnedBody.to_json)
    status HTTP_OK
  end


  put '/v2/patientsextended/:patient_id' do
    begin
      access_token, patient_id = get_oauth_token, params[:patient_id]
      request_body = get_request_JSON
      data  = CCAuth::OAuth2.new.token_scope access_token
      url = "#{ApiService::API_SVC_URL}business_entity/#{data[:scope][:business_entity_id]}/patients/#{patient_id}/createextended.json?token=#{access_token}"
      response = RestClient.put url, request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
    rescue => e
      begin
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse response.body
    returned_value = parsed["patient"]["external_id"]
    response_hash = { :patient => returned_value.to_s }
    body(response_hash.to_json); status HTTP_OK
  end


  # /patients/{guid}
  # /v2/patients/{guid}
  # /v2/patients/{integer_id}
  get /(\/v2\/)?patients\/(?<patient_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})|[0-9]*)/ do |patient_id|
    require 'pry'; binding.pry
    pass if params[:patient_id] == "search"
    begin
      patient_id = params[:patient_id]
      url   = "#{ApiService::API_SVC_URL}businesses/#{current_business_entity}/patients/#{patient_id}"
      url  += is_this_numeric(patient_id) ? ".json" : "/externalid.json"
      url  += "?token=#{escaped_oauth_token}&do_full_export=true"
      response = RestClient.get url, extapikey: ApiService::APP_API_KEY
    rescue => e
      begin
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse(response.body)
    parsed["patient"]["id"] = parsed["patient"]["external_id"]
    body(parsed.to_json); status HTTP_OK
  end


  # /v2/patients
  # /v2/patients/create (legacy)
  post /\/v2\/(patients\/create|patients)/ do
    begin
      request_body = get_request_JSON
      url          = "#{ApiService::API_SVC_URL}businesses/#{current_business_entity}/patients.json?token=#{escaped_oauth_token}"
      response     = RestClient.post url, request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
    rescue => e
      begin
          exception = error_handler_filter(e.response)
          errmsg = "Patient Creation Failed - #{exception}"
          api_svc_halt e.http_code, errmsg
      rescue
          errmsg = "#{e.message}"
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    returnedBody  = JSON.parse response.body
    value         = returnedBody["patient"]["external_id"]
    response_hash = { :patient => value.to_s }
    body(response_hash.to_json); status HTTP_CREATED
  end


  get '/v2/patients/search?' do
    search_limit = request_body['limit'].to_s

    #business_entity_patient_search        /businesses/:business_entity_id/patients/search.:format  {:controller=>"patients", :action=>"search_by_business_entity"}
    #http://localservices.carecloud.local:3000/businesses/1/patients/search.json?token=<token>&search=test%20smith&limit=50
    #/businesses/:business_entity_id/patients/search.:format

    urlpatient = webservices_uri "businesses/#{current_business_entity}/patients/search.json",
                                 {token: escaped_oauth_token, limit: search_limit, search: search_data}

    response = rescue_service_call 'Search' do
      RestClient.get(urlpatient)
    end

    returnedBody = JSON.parse(response.body)
    returnedBody["patients"].each {|x| x["id"] = x["external_id"]}
    body(returnedBody.to_json)
    status HTTP_OK
  end

end
