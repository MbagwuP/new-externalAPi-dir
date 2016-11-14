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
    returnedBody["patients"].each {|patient| patient['gender_code'] = DemographicCodes::Converter.cc_id_to_code(DemographicCodes::Gender, patient.delete('gender_id')) }
    body(returnedBody.to_json)
    status HTTP_OK
  end


  put '/v2/patientsextended/:patient_id' do
    begin
      access_token, patient_id = get_oauth_token, params[:patient_id]
      request_body = get_request_JSON
      data  = CCAuth::OAuth2Client.new.authorization access_token
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

  get '/v2/patients/:patient_id/insurances' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Patient ID must be a valid GUID."}' unless params[:patient_id].is_guid?
    insurancesurl = webservices_uri "businesses/#{current_business_entity}/patients/#{params[:patient_id]}/insurance_policies.json",
      token: escaped_oauth_token
    resp = rescue_service_call 'Patient Insurance' do
      RestClient.get(insurancesurl, :api_key => APP_API_KEY)
    end
    
    @profiles = JSON.parse(resp)
    @patient_id = params[:patient_id]

    jbuilder :list_patient_insurance_profiles
  end


  # /patients/{guid}
  # /v2/patients/{guid}
  # /v2/patients/{integer_id}
  get /\/v2\/patients\/(?<patient_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})|[0-9]*)$/ do |patient_id|
    pass if params[:patient_id] == "search" || params[:patient_id].blank?
    begin
      patient_id = params[:patient_id]
      url   = "#{ApiService::API_SVC_URL}businesses/#{current_business_entity}/patients/#{patient_id}"
      url  += is_this_numeric(patient_id) ? ".json" : "/externalid.json"
      url += "?do_full_export=true"
      if (current_internal_request_header)
        internal_signed_request = sign_internal_request(url: url, method: :get)
        response = internal_signed_request.execute
      else
        url  += "&token=#{escaped_oauth_token}"
        response = RestClient.get url, extapikey: ApiService::APP_API_KEY
      end
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
    parsed['patient']['gender_code'] = DemographicCodes::Converter.cc_id_to_code(DemographicCodes::Gender, parsed['patient']['gender_id'])
    parsed['patient'].delete('primary_care_physician_id')
    parsed = Fhir::PatientPresenter.new(parsed['patient']).as_json if request.accept.first.to_s == 'application/json+fhir'
    body(parsed.to_json); status HTTP_OK
  end

 
  # /v2/patients
  # /v2/patients/create (legacy)
  post /\/v2\/(patients\/create|patients)$/ do
    begin
      request_body = get_request_JSON
      convert_demographic_codes!(request_body)

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
    returnedBody["patients"].each {|patient| patient['gender_code'] = DemographicCodes::Converter.cc_id_to_code(DemographicCodes::Gender, patient.delete('gender_id')) }
    body(returnedBody.to_json)
    status HTTP_OK
  end

  put '/v2/patients/:patient_id'  do
    begin
      request_body = get_request_JSON
      convert_demographic_codes!(request_body)

      url = "#{ApiService::API_SVC_URL}businesses/#{current_business_entity}/patients/#{params[:patient_id]}.json?token=#{escaped_oauth_token}"
      response = RestClient.put url, request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
    rescue => e
      begin
          exception = error_handler_filter(e.response)
          errmsg = "Patient Update Failed - #{exception}"
          api_svc_halt e.http_code, errmsg
      rescue
          errmsg = "#{e.message}"
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    status HTTP_NO_CONTENT
  end

  get '/v2/patients/:patient_id/balance' do
    patient_id = params[:patient_id]
    urlbalance = webservices_uri "patients/#{patient_id}/accounts_receivables.json", token: escaped_oauth_token, business_entity_id: current_business_entity

    response = rescue_service_call 'Patient Balance' do
      RestClient.get(urlbalance)
    end

    @resp = JSON.parse(response.body)
    status HTTP_OK
    jbuilder :patient_balance
  end

  post '/v2/patients/:patient_id/insurances' do
    request_body = get_request_JSON

    insurance_policies = []
    if request_body['insurance_profile']['primary_insurance_policy']
      request_body['insurance_profile']['primary_insurance_policy']['priority'] = 1
      insurance_policies << request_body['insurance_profile'].delete('primary_insurance_policy')
    end
    if request_body['insurance_profile']['secondary_insurance_policy']
      request_body['insurance_profile']['secondary_insurance_policy']['priority'] = 2
      insurance_policies << request_body['insurance_profile'].delete('secondary_insurance_policy')
    end
    if request_body['insurance_profile']['tertiary_insurance_policy']
      request_body['insurance_profile']['tertiary_insurance_policy']['priority'] = 3
      insurance_policies << request_body['insurance_profile'].delete('tertiary_insurance_policy')
    end
    if request_body['insurance_profile']['quaternary_insurance_policy']
      request_body['insurance_profile']['quaternary_insurance_policy']['priority'] = 4
      insurance_policies << request_body['insurance_profile'].delete('quaternary_insurance_policy')
    end
    request_body['insurance_profile']['insurance_policies'] = insurance_policies

    responsible_party_relationship = request_body['insurance_profile'].delete('responsible_party_relationship')
    patient_id = params[:patient_id]
    request_body['insurance_profile']['responsible_party_relationship_type_id'] = person_relationship_types[responsible_party_relationship]

    request_body['insurance_profile']['responsible_party']['phones'] = request_body['insurance_profile']['responsible_party']['phones'].map do |x|
      phone_type = x.delete('phone_type')
      x['phone_type_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::PhoneType, phone_type)
      x
    end

    request_body['insurance_profile']['responsible_party']['addresses'] = request_body['insurance_profile']['responsible_party']['addresses'].map do |x|
      state = x.delete('state')
      x['state_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::State, state)
      country = x.delete('country')
      x['country_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::Country, country)
      x
    end

    gender = request_body['insurance_profile']['responsible_party'].delete('gender')
    request_body['insurance_profile']['responsible_party']['gender_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::Gender, gender)

    request_body['insurance_profile']['insurance_policies'] = request_body['insurance_profile']['insurance_policies'].map do |x|

      if x['payer'] && x['payer']['address'] && x['payer']['address']['state']
        state = x['payer']['address'].delete('state')
        x['payer']['address']['state_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::State, state)
        country = x['payer']['address'].delete('country')
        x['payer']['address']['country_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::Country, country)
      end

      insured_person_relationship = x.delete('insured_person_relationship')
      insurance_policy_type = x.delete('insurance_policy_type')
      x.rename_key('group_number', 'policy_id') # the UI says "group number", but the DB column is "policy_id"

      gender = x['insured'].delete('gender')
      x['insured']['gender_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::Gender, gender)

      x['insured_person_relationship_type'] = person_relationship_types[insured_person_relationship]
      x['insurance_policy_type_id'] = insurance_policy_types[insurance_policy_type]
      if x['insured']['phones']
        x['insured']['phones'].each do |y|
          phone_type = y.delete('phone_type')
          y['phone_type_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::PhoneType, phone_type)
          y
        end
      end
      if x['insured']['addresses']
        x['insured']['addresses'].each do |y|
          state = y.delete('state')
          y['state_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::State, state)
          country = y.delete('country')
          y['country_id'] = DemographicCodes::Converter.code_to_cc_id(DemographicCodes::Country, country)
          y
        end
      end
      x
    end

    urlinsurance = webservices_uri "patients/#{patient_id}/insurance_profiles/create.json", token: escaped_oauth_token, business_entity_id: current_business_entity

    @resp = rescue_service_call 'Patient Insurance' do
      RestClient.post(urlinsurance, request_body.to_json, content_type: :json)
    end

    @resp = JSON.parse(@resp.body)
    status HTTP_CREATED
    jbuilder :create_insurance
  end

end
