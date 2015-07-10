class ApiService < Sinatra::Base

  post '/v2/patients/search?' do
    ## Validate the input parameters
    request_body = get_request_JSON
    searching_by_fields = request_body['fields'].present?
    using_old_search_format = request_body['search'].present?
    searching_by_terms = request_body['terms'].present? || using_old_search_format

    if (searching_by_terms && searching_by_fields) || (!searching_by_terms && !searching_by_fields)
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"You must search by either a list of terms, or specific terms against specific fields."}'
    end

    if using_old_search_format
      search_data = ""
      request_body['search'].each { |x|
        search_data = search_data + x["term"] + " "
      }
      request_payload = {search: search_data}
    elsif searching_by_terms
      search_data = request_body['terms'].join(' ')
      request_payload = {search: search_data}
    elsif searching_by_fields
      request_payload = {fields: request_body['fields']}
    end

    request_payload[:limit] = request_body['limit'].to_s

    #business_entity_patient_search        /businesses/:business_entity_id/patients/search.:format  {:controller=>"patients", :action=>"search_by_business_entity"}
    #http://localservices.carecloud.local:3000/businesses/1/patients/search.json?token=<token>&search=test%20smith&limit=50
    #/businesses/:business_entity_id/patients/search.:format
    urlpatient = webservices_uri "businesses/#{current_business_entity}/patients/search.json", token: escaped_oauth_token

    response = rescue_service_call 'Patient Search' do
      RestClient.post(urlpatient, request_payload)
    end

    returnedBody = JSON.parse(response.body)
    returnedBody["patients"].each {|x| x.rename_key('external_id', 'id') }
    returnedBody["patients"].each {|patient| patient['gender_code'] = cc_id_to_code('gender', patient.delete('gender_id')) }
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
  get /\/v2\/patients\/(?<patient_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})|[0-9]*)/ do |patient_id|
    pass if params[:patient_id] == "search" || params[:patient_id].blank?
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
    parsed['patient'].rename_key 'external_id', 'id'
    parsed['patient']['business_entity_id'] = current_business_entity
    parsed['patient']['gender_code'] = cc_id_to_code('gender', parsed['patient']['gender_id'])
    body(parsed.to_json); status HTTP_OK
  end


  # /v2/patients
  # /v2/patients/create (legacy)
  post /\/v2\/(patients\/create|patients)/ do
    begin
      request_body = get_request_JSON
      request_body['patient']['gender_id'] = code_to_cc_id('gender', request_body['patient'].delete('gender_code')) unless request_body['patient']['gender_id'].present?
      request_body['patient']['race_id'] = code_to_cc_id('race', request_body['patient'].delete('race_code')) unless request_body['patient']['race_id'].present?
      request_body['patient']['marital_status_id'] = code_to_cc_id('marital_status', request_body['patient'].delete('marital_status_code')) unless request_body['patient']['marital_status_id'].present?
      request_body['patient']['language_id'] = code_to_cc_id('language', request_body['patient'].delete('language_code')) unless request_body['patient']['language_id'].present? 
      request_body['patient']['drivers_license_state_id'] = code_to_cc_id('state', request_body['patient'].delete('drivers_license_state_code')) unless request_body['patient']['drivers_license_state_id'].present?
      request_body['patient']['employment_status_id'] = code_to_cc_id('employment_status', request_body['patient'].delete('employment_status_code')) unless request_body['patient']['employment_status_id'].present?
      request_body['patient']['ethnicity_id'] = code_to_cc_id('ethnicity', request_body['patient'].delete('ethnicity_code')) unless request_body['patient']['ethnicity_id'].present?
      request_body['patient']['student_status_id'] = code_to_cc_id('student_status', request_body['patient'].delete('student_status_code')) unless request_body['patient']['student_status_id'].present?

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
    returnedBody["patients"].each {|patient| patient["id"] = patient["external_id"] }
    returnedBody["patients"].each {|patient| patient['gender_code'] = cc_id_to_code('gender', patient.delete('gender_id')) }
    body(returnedBody.to_json)
    status HTTP_OK
  end

end
