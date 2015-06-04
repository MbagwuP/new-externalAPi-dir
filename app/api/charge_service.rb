#
# File:       charge_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base
#{
#     "charge": {
#         "provider_id": "4817",
#         "insurance_profile_id": "",
#         "attending_provider_id": "",
#         "referring_physician_id": "",
#         "supervising_provider_id": "",
#         "authorization_id": "",
#         "clinical_case_id": "",
#         "location_id": "",
#         "encounter_id": "",
#         "debit_transaction_id": "",
#         "start_time": "2014-01-03",
#         "end_time": "2014-01-03",
#         "units": 1,
#         "procedure_code": "99253",
#         "procedure_short_description": "",
#         "diagnosis1_code": "285.9",
#         "diagnosis1_pointer": 1,
#         "diagnosis2_code": "",
#         "diagnosis2_pointer": "",
#         "diagnosis3_code": "",
#         "diagnosis3_pointer": "",
#         "diagnosis4_code": "",
#         "diagnosis4_pointer": "",
#         "diagnosis5_code": "",
#         "diagnosis5_pointer": "",
#         "diagnosis6_pointer":"",
#         "diagnosis7_code": "",
#         "diagnosis7_pointer": "",
#         "diagnosis8_code": "",
#         "diagnosis8_pointer": "",
#         "modifier1_code": "",
#         "modifier2_code": "",
#         "modifier3_code": "",
#         "modifier4_code": ""
#     },
#     "clinical_case": {
#         "clinical_case_type_id": "1",
#         "effective_from": "1",
#         "effective_to": "1",
#         "onset_date": "1",
#         "hospitalization_date_from": "1",
#         "hospitalization_date_to": "1",
#         "auto_accident_state_id": "1",
#         "newborn_weight": "1",
#         "pregnancy_indicator": "1",
#         "location_id": "1",
#         "accident_type_id": "1",
#         "claim_number": "1",
#         "adjuster_contact_id": "1",
#         "order_date": "1",
#         "initial_treatment_date": "1",
#         "referral_date": "1",
#         "last_seen_date": "1",
#         "acute_manifestation_date": "1"
#     }
#}
# server response:
# --> if appointment created: 201, with charge id returned
# --> if not authorized: 401
# --> if patient not found: 404
# --> if bad request: 400
  post '/v1/charge/:patient_id/create?' do
    # Validate the input parameters
    request_body = get_request_JSON
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patient_id = params[:patient_id]
    patient_id.slice!(/^patient-/)
    patient_id = get_internal_patient_id(patient_id , business_entity, pass_in_token)
    provider_ids = get_providers_by_business_entity(business_entity, pass_in_token)
    check_for_valid_provider(provider_ids, request_body['charge']['provider_id']) if request_body['charge']['provider_id']
    request_body['charge']['icd_indicator'] = validate_icd_indicator(request_body['charge']['icd_indicator'])

    ## validate provider id
    #providerid = request_body['charge']['provider_id']

    ## validate the provider
    #providerids = get_providers_by_business_entity(business_entity, pass_in_token)

    ## validate the request based on token
    #check_for_valid_provider(providerids, providerid)

    #http://localservices.carecloud.local:3000/charges/create.json?token=
    urlcharge = ''
    urlcharge << API_SVC_URL
    urlcharge << 'charges/'
    urlcharge << patient_id
    urlcharge << '/business_entity/'
    urlcharge << business_entity
    urlcharge << '/create.json?token='
    urlcharge << CGI::escape(pass_in_token)

    #LOG.debug("url for charge create: " + urlcharge)
    #LOG.debug(request_body.to_json)

    begin
      response = RestClient.post(urlcharge, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        error = e.response.body
        error_json = JSON.parse(error)
        #used to prevent giving out too much data.
        error_json["error"]["message"] = "Internal Server Error" if (error_json["error"]["message"].size > 80)
        errmsg = "Charge Creation Failed - #{error_json["error"]["error_code"]} - #{error_json["error"]["message"]}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    #return_value = parsed["id"]
    #body("Charge has been created, Confirmation Code: #{return_value}")
    parsed = JSON.parse(response.body)
    body("A Charge has successfully posted for patient: #{params[:patient_id]}" + ", To Encounter : #{parsed[0]['encounter_id']}")
    status HTTP_CREATED

  end


  # {
  #     "debit": {
  #     "entered_at": "",
  #     "posting_date": "",
  #     "effective_date": "",
  #     "period_closed_date": "",
  #     "amount": "123",
  #     "balance": "0",
  #     "value": "111",
  #     "value_balance": "0",
  #     "batch_number": "",
  #     "date_first_statement": "",
  #     "date_last_statement": "",
  #     "statement_count": "",
  #     "note_set_id": "",
  #     "document_set_id": "",
  #     "transaction_status": ""
  # },
  #     "simple_charge": {
  #     "provider_id": "57",
  #     "location_id": "3695",
  #     "units": "1",
  #     "patient_payments_applied": "100",
  #     "patient_adjustments_applied": "0",
  #     "simple_charge_type": "25462",
  #     "description": "Simple Charge Test"
  # }
  # }

  post '/v1/simple_charge/:patient_id/create?' do
    # Validate the input parameters
    request_body = get_request_JSON
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patient_id = params[:patient_id]
    patient_id.slice!(/^patient-/)
    patient_id = get_internal_patient_id(patient_id , business_entity, pass_in_token)
    #provider_ids = get_providers_by_business_entity(business_entity, pass_in_token)
    #check_for_valid_provider(provider_ids, request_body['charge']['provider_id']) if request_body['charge']['provider_id']

    ## validate provider id
    #providerid = request_body['charge']['provider_id']

    ## validate the provider
    #providerids = get_providers_by_business_entity(business_entity, pass_in_token)

    ## validate the request based on token
    #check_for_valid_provider(providerids, providerid)

    #http://localservices.carecloud.local:3000/charges/create.json?token=
    urlcharge = ''
    urlcharge << API_SVC_URL
    urlcharge << 'simple_charges/'
    urlcharge << patient_id
    urlcharge << '/business_entity/'
    urlcharge << business_entity
    urlcharge << '/create.json?token='
    urlcharge << CGI::escape(pass_in_token)

    #LOG.debug("url for charge create: " + urlcharge)
    #LOG.debug(request_body.to_json)

    begin
      response = RestClient.post(urlcharge, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        error = e.response.body
        error_json = JSON.parse(error)
        #used to prevent giving out too much data.
        error_json["error"]["message"] = "Internal Server Error" if (error_json["error"]["message"].size > 40)
        errmsg = "Charge Creation Failed - #{error_json["error"]["error_code"]} - #{error_json["error"]["message"]}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    #return_value = parsed["id"]
    #body("Charge has been created, Confirmation Code: #{return_value}")
    parsed = JSON.parse(response.body)
    body("A Simple Charge has successfully posted for patient: #{params[:patient_id]}")
    status HTTP_CREATED

  end

  # get Simple Charge Types
  # parameters -> Token
  # returns array of Simple Charge Types
  get '/v1/simple_charge_types?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    #simple_charges_types/business_entity/:business_entity/get(.:format)
    url = "#{API_SVC_URL}/simple_charges_types/business_entity/#{business_entity}/get.json?token=#{pass_in_token}"

    begin
      response = RestClient.get(url)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Simple Charge Type Look Up Failed- #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Simple Charge Type Look Up Failed- #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

      parsed = JSON.parse(response.body)
      body(parsed.to_json)
      status HTTP_OK
  end



  #returns charges

  get '/v1/charges/:patient_id?' do

    #LOG.debug("0")
    pass_in_token = CGI::unescape(params[:authentication])
    #business_entity = get_business_entity(pass_in_token)
    #LOG.debug("0.5")
    pid = params[:patient_id]
    #LOG.debug("1")
    #LOG.debug(pid)

    url = ''
    url << API_SVC_URL
    url << 'patient_id/'
    url <<  pid
    url << '/charge/listbypatient.json?token='
    url << CGI::escape(pass_in_token)

    #LOG.debug(url)
    #LOG.debug("2")
    begin
      response = RestClient.get(url)
    rescue => e
      begin
        errmsg = "Patient charge Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    #LOG.debug("hit me")
    #LOG.debug(response)
    if !response
      body("There are no charges for this patient")
    else
      parsed = JSON.parse(response.body)
      body(parsed.to_json)
    end
    status HTTP_OK
  end

end