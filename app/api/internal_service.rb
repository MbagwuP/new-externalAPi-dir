#
# File:       internal_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base


  #used to get list of callbacks
  #notification_id = callback id
  #start_date = from date of notification lookup
  #end_date = end date of notification lookup
  #business_entity_id = BE
  #mirth_url = reprocess messages to mirth url.

  get '/v1/notifications/:notification_id/:start_date/:end_date/:business_entity_id' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    getcallbacks = ''
    getcallbacks << API_SVC_URL
    getcallbacks << 'notification_callbacks/'
    getcallbacks << params[:notification_id]
    getcallbacks << ".json?token="
    getcallbacks << CGI::escape(pass_in_token)

    begin
      callback = RestClient.get(getcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback Error - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    Exception.raise("Notification Callback Error") if callback.blank?

    callback_info = JSON.parse(callback.body)
    url = callback_info['notification_callback']['notification_callback_url']
    LOG.debug(url)

    urlcallbacks = ''
    urlcallbacks << API_SVC_URL
    urlcallbacks << 'notification_callbacks/'
    urlcallbacks << params[:start_date]
    urlcallbacks << "/"
    urlcallbacks << params[:end_date]
    urlcallbacks << '/id/'
    urlcallbacks << params[:notification_id]
    urlcallbacks << '/'
    urlcallbacks << business_entity
    urlcallbacks << ".json?token="
    urlcallbacks << CGI::escape(pass_in_token)
    LOG.debug(urlcallbacks)

    begin
      response = RestClient.get(urlcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback look up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    body(parsed.to_json)
    status HTTP_OK

  end

  #used to find notifications and reprocess callbacks
  #notification_id = callback id
  #start_date = from date of notification lookup
  #end_date = end date of notification lookup
  #business_entity_id = BE
  #mirth_url = reprocess messages to mirth url.

  get '/v1/reprocess/notifications/:notification_id/:start_date/:end_date/:business_entity_id' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    getcallbacks = ''
    getcallbacks << API_SVC_URL
    getcallbacks << 'notification_callbacks/'
    getcallbacks << params[:notification_id]
    getcallbacks << ".json?token="
    getcallbacks << CGI::escape(pass_in_token)

    LOG.debug("URL 1")

    begin
      callback = RestClient.get(getcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback Error - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    LOG.debug("URL 2")
    LOG.debug(callback)

    callback_info = JSON.parse(callback.body)
    url = callback_info['notification_callback']['notification_callback_url']
    LOG.debug(url)

    urlcallbacks = ''
    urlcallbacks << API_SVC_URL
    urlcallbacks << 'notification_callbacks/'
    urlcallbacks << params[:start_date]
    urlcallbacks << "/"
    urlcallbacks << params[:end_date]
    urlcallbacks << '/id/'
    urlcallbacks << params[:notification_id]
    urlcallbacks << ".json?token="
    urlcallbacks << CGI::escape(pass_in_token)
    LOG.debug(urlcallbacks)

    begin
      response = RestClient.get(urlcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback look up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    parsed.each do |audit|
      @temp_hash = {
          "event_raised" => "PatientUpdate",
          "event_type" => audit['audit']['audit_type_id'],
          "id" =>  audit['audit']['external_id'],
          "isnew" => false,
          "business" => audit['audit']['business_entity_id'],
          "status"=> "A"
      }
      @json_request = @temp_hash.to_json
      RestClient.post(url,@json_request, :content_type => :json)
    end
    body(parsed.to_json)
    status HTTP_OK
  end


  #get notification callbacks since a date
  #URL: v1/notification_callbacks/2013-12-30/85152eb3-0140-4812-9428-8ceee06a25bc?authentication=
  #params ex.
  #date = 2013-12-30
  #notification_callback id = 85152eb3-0140-4812-9428-8ceee06a25bc


  get '/v1/notification_callbacks/:date/:notification_id?' do
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    urllocation = ''
    urllocation << API_SVC_URL
    urllocation << 'notification_callbacks/'
    urllocation << params[:date]
    urllocation << '/id/'
    urllocation << params[:notification_id]
    urllocation << ".json?token="
    urllocation << CGI::escape(pass_in_token)
    #LOG.debug(urllocation)

    begin
      response = RestClient.get(urllocation)
    rescue => e
      begin
        errmsg = "Notification Callback look up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK
  end

  #used for interface for outbound SIU messages (HL7)
  get '/v1/internal/apt/outbound/:appointmentid/:business_entity?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    appointmentid = params[:appointmentid]

    # http://localservices.carecloud.local
    #   /appointments/1/abcd93832/listbyexternalid2.json
    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << params[:business_entity]
    urlappt << '/'
    urlappt << appointmentid
    urlappt << '/listbyexternalid2.json?token='
    urlappt << CGI::escape(pass_in_token)
    urlappt << "&vitals=#{params[:vitals]}" if params[:vitals]
    urlappt << "&diagnosis_codes=#{params[:diagnosis_codes]}" if params[:diagnosis_codes]


    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look up failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    apt = JSON.parse(response.body)
    LOG.debug(apt)
    patientid = apt['appointment']['patient_ext_id']

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << params[:business_entity]
    urlpatient << '/patients/'
    urlpatient <<  patientid
    urlpatient << '/externalid.json?token='
    urlpatient << CGI::escape(pass_in_token)
    urlpatient << '&do_full_export=true'

    begin
      resp = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Patient Look up failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    patient = JSON.parse(resp.body)
    patient['id'] = patient['external_id']

    patient["appointment"] = apt

    LOG.debug(patient)
    body(patient.to_json)

    status HTTP_OK
  end


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
  post '/v1/internal/charge/:patient_id/create?' do
    # Validate the input parameters
    request_body = get_request_JSON
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patient_id = params[:patient_id]
    patient_id.slice!(/^patient-/)
    filtered_patient_id = get_internal_patient_id_by_patient_number(patient_id , business_entity, pass_in_token)
    provider_ids = get_providers_by_business_entity(business_entity, pass_in_token)
    check_for_valid_provider(provider_ids, request_body['charge']['provider_id']) if request_body['charge']['provider_id']

    #check for patient by patient_number, legacy_id, external_id


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
    urlcharge << filtered_patient_id
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
    body("A Charge has successfully posted for patient: #{filtered_patient_id}" + ", To Encounter : #{parsed[0]['encounter_id']}")
    status HTTP_CREATED

  end




end
