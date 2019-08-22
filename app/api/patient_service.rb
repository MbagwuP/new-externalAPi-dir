#
# File:       patient_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base

  #  get patient by id
  #
  # GET /v1/patients/<patientid#>?authentication=<authenticationToken>
  #
  # Params definition
  # :patientid     - the patient identifier number
  #    (ex: patient-1234)
  #
  # server action: Return patient information
  # server response:
  # --> if patient found: 200, with patient data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/patients/:patientid?' do
    # Validate the input parameters
    # validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    #
    # api_svc_halt HTTP_FORBIDDEN if params[:authentication] == nil
    #
    pass_in_token = CGI::unescape(params[:authentication])
    # #format to what the devservice needs
    business_entity = get_business_entity(pass_in_token)
    patientid = params[:patientid]
    patientid.slice!(/^patient-/)

    ## if the patient id is all numeric call getById
    if is_this_numeric(patientid)
      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity
      urlpatient << '/patients/'
      urlpatient << patientid
      urlpatient << '.json?token='
      urlpatient << CGI::escape(pass_in_token)
      urlpatient << '&do_full_export=true'
    else

      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity
      urlpatient << '/patients/'
      urlpatient << patientid
      urlpatient << '/externalid.json?token='
      urlpatient << CGI::escape(pass_in_token)
      urlpatient << '&do_full_export=true'

    end

    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    parsed["patient"]["patient_id"] = parsed["patient"]["id"]
    parsed["patient"]["id"] = parsed["patient"]["external_id"]
    parsed['patient'].delete('primary_care_physician_id')

    #LOG.debug(parsed)

    body(parsed.to_json)

    status HTTP_OK

  end

  #Use to test for production
  #have to make sure master token likes the pharmacy additions

  get '/productiontest/patients/:patientid?' do
    # Validate the input parameters
    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)

    api_svc_halt HTTP_FORBIDDEN if params[:authentication] == nil

    pass_in_token = CGI::unescape(params[:authentication])
    #format to what the devservice needs
    business_entity = get_business_entity(pass_in_token)
    patientid = params[:patientid]
    patientid.slice!(/^patient-/)

    ## if the patient id is all numeric call getById
    if is_this_numeric(patientid)
      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity
      urlpatient << '/patients/'
      urlpatient << patientid
      urlpatient << '.json?token='
      urlpatient << CGI::escape(pass_in_token)
      urlpatient << '&do_full_export=true'
    else

      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity
      urlpatient << '/patients/'
      urlpatient << patientid
      urlpatient << '/externalid.json?token='
      urlpatient << CGI::escape(pass_in_token)
      urlpatient << '&do_full_export=true'

    end

    begin
      response = RestClient.get(urlpatient)
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

    #LOG.debug(parsed)
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'patients/'
    urlpatient << patientid
    urlpatient << '/pharmacies'
    urlpatient << '.json?token='
    urlpatient << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Retrieving Patient Pharmacy Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed2 = JSON.parse(response.body)

    #LOG.debug(parsed2)

    results = []
    results << parsed
    results << parsed2

    LOG.debug(results)

    body(results.to_json)

    status HTTP_OK

  end




  #  get patient by legacy id
  #
  # GET /v1/patients/legacy/<patientid#>?authentication=<authenticationToken>
  #
  # Params definition
  # :legacy-patientid     - the legacy patient identifier number
  #    (ex: patient-1234)
  #
  # server action: Return patient information
  # server response:
  # --> if patient found: 200, with patient data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/patients/legacy/:patientid?' do

    # Validate the input parameters
    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]

    #format to what the devservice needs
    patientid.slice!(/^patient-/)

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

    ## http://localservices.carecloud.local:3000/businesses/1/patients/1304202/legacyid.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << patientid
    urlpatient << '/legacyid.json?token='
    urlpatient << CGI::escape(pass_in_token)
    urlpatient << '&do_full_export=true'

    begin
      response = RestClient.get(urlpatient)
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

    body(parsed.to_json)

    status HTTP_OK

  end


  #  get patient by other means
  #
  # GET /v1/patients/othermeans/<id#>?authentication=<authenticationToken>
  #
  # Params definition
  # :id-chart of legacy id     - the legacy patient identifier number
  #    (ex: 1234)
  #
  # server action: Return patient information
  # server response:
  # --> if patient found: 200, with patient data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/patients/othermeans/:patientid?' do

    patientid = params[:patientid]

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    LOG.debug(business_entity)
    ## http://localservices.carecloud.local:3000/businesses/:business_entity_id/patients/:id/othermeans.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << patientid
    urlpatient << '/othermeans.json?token='
    urlpatient << CGI::escape(pass_in_token)

    begin
      LOG.debug(urlpatient)

      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Retrieving Patient Data (by other means1) Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK

  end


  #  get patient by provider id
  #
  # GET /v1/patients/provider/<providerid#>?authentication=<authenticationToken>
  #
  # Params definition
  # :providerid     - the primary provider id
  #    (ex: patient-1234)
  #
  # server action: Return patient information
  # server response:
  # --> if patient found: 200, with patient data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/patients/provider/:providerid?' do

    # Validate the input parameters
    providerid = params[:providerid]

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

    ## validate the provider
    providerids = get_providers_by_business_entity(business_entity, pass_in_token)

    ## validate the request based on token
    check_for_valid_provider(providerids, providerid)

    ## http://localservices.carecloud.local:3000/businesses/1/providers/2/sync_list.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/providers/'
    urlpatient << providerid
    urlpatient << '/sync_list.json?token='
    urlpatient << CGI::escape(pass_in_token)

    #LOG.debug("Before Providers cal")

    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)

    #LOG.debug(parsed)
    body(parsed.to_json)

    #LOG.debug("good")
    status HTTP_OK


  end


  #  get patients by business_entity
  #
  # GET /v1/patients/provider/<providerid#>?authentication=<authenticationToken>
  #
  # Params definition
  # :providerid     - the primary provider id
  #    (ex: patient-1234)
  #
  # server action: Return patient information
  # server response:
  # --> if patient found: 200, with patient data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  #'/patients/business_entity/:business_entity_id/get_all_patients.:format
  get '/v1/findallpatients?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlpatient = "#{API_SVC_URL}patients/business_entity/#{business_entity}/get_all_patients.json?token=#{CGI::escape(pass_in_token)}"
    LOG.debug(urlpatient)
    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    data = JSON.parse(response.body)
    body(data.to_json)
    status HTTP_OK
 end


  #  create a patient
  #
  #  POST /v1/patients/create?authentication=<authenticationToken>
  #
  # Params definition
  # JSON:
  # {
  #    "patient": {
  #    "first_name": "bob",
  #    "last_name": "smith",
  #    "middle_initial": "E",
  #    "email": "no@email.com",
  #    "prefix": "mr",
  #    "suffix": "jr",
  #    "ssn": "123-45-6789",
  #    "gender_id": "1",
  #    "date_of_birth": "2000-03-12",
  #    "race_id" : 3,
  #    "marital_status_id": 5,
  #    "language_id" : 478,
  #    "chart_number": "2299238332",
  #    "drivers_license_number": "M9283732323",
  #    "drivers_license_state_id": "22",
  #    "employment_status_id":1,
  #    "school_name": "Regional High School",
  #    "employer_name" : "Employer Name",
  #    "account_number": "282372389948724",
  #    "legacy_patient_id":"923883",
  #    "employer_phone_number":"8887776565",
  #    "ethnicity_id": 1,
  #    "student_status_id": 1
  #
  # },
  #    "addresses": [ {
  #                       "line1": "123 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225,
  #    "is_primary":"t"
  # }],
  #    "phones": [
  #    {
  #        "phone_number": "5552221212",
  #    "phone_type_id": "3",
  #    "extension": "3433",
  #    "is_primary": "t"
  # },
  #    {
  #        "phone_number": "3332221212",
  #    "phone_type_id": "2",
  #    "extension": "5566"
  # }
  # ]
  # }
  #
  # Input requirements
  #   - date_of_birth: must be a valid Date. Hint: YYYY-MM-DD, YYYY/MM/DD, YYYYMMDD
  #   - gender ids:
  #       id;description;code
  #       3;"Unknown";"U"
  #       2;"Female";"F"
  #       1;"Male";"M"
  #   - country_id:
  #       225;United States
  #   - phone_type_id:
  #       id;description;code
  #       1;"Business";"B"
  #       11;"Main";"M"
  #       9;"Fax";"F"
  #       7;"TollFree";"TF"
  #       6;"VOIP";"V"
  #       5;"Skype";"S"
  #       4;"Pager";"P"
  #       3;"Cell";"C"
  #       2;"Home";"H"
  #       8;"SMS";"SMS"
  #       10;"State 800";"S800"
  #       12;"National 800";"N800"
  #
  # server action: Return patient id
  # server response:
  # --> if success: 201, with patient id
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/patients/create?' do

    # Validate the input parameters
    request_body = get_request_JSON

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    request_body['patient'].delete('primary_care_physician_id') if request_body['patient']

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients.json?commit_search=false&token='
    urlpatient << CGI::escape(params[:authentication])

    begin
      response = RestClient.post(urlpatient, request_body.to_json, :content_type => :json)
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

    returnedBody = JSON.parse(response.body)
    value = returnedBody["patient"]["external_id"]
    the_response_hash = {:patient => value.to_s}
    #Client Related: Return just patient id
    body(the_response_hash.to_json)
    status HTTP_CREATED

  end

  # {
  #    "patient_data": {
  #    "patient": {
  #    "first_name": "bob",
  #    "last_name": "smith",
  #    "middle_initial": "E",
  #    "email": "no@email.com",
  #    "prefix": "mr",
  #    "suffix": "jr",
  #    "ssn": "123-45-6789",
  #    "gender_id": "1",
  #    "date_of_birth": "2000-03-12",
  #    "race_id": 3,
  #    "marital_status_id": 5,
  #    "language_id": 478,
  #    "chart_number": "2299238332",
  #    "drivers_license_number": "M9283732323",
  #    "drivers_license_state_id": "22",
  #    "employment_status_id": 1,
  #    "school_name": "Regional High School",
  #    "employer_name": "Employer Name",
  #    "account_number": "282372389948724",
  #    "legacy_patient_id": "923883",
  #    "employer_phone_number": "8887776565",
  #    "ethnicity_id": 1,
  #    "student_status_id": 1
  # },
  #    "addresses": [
  #    {
  #        "line1": "123 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225,
  #    "is_primary": "t"
  # }
  # ],
  #    "phones": [
  #    {
  #        "phone_number": "5552221212",
  #    "phone_type_id": "3",
  #    "extension": "3433",
  #    "is_primary": "t"
  # },
  #    {
  #        "phone_number": "3332221212",
  #    "phone_type_id": "2",
  #    "extension": "5566"
  # }
  # ]
  # },
  #    "insurance_information": {
  #    "insurance_profile": {
  #    "responsible_party_relationship": "OTHER",
  #    "is_default": true,
  # "responsible_party": {
  #    "first_name": "bob",
  #    "last_name": "lee",
  #    "middle_initial": "A",
  #    "date_of_birth": "2000-08-09",
  #    "ssn": "333-55-6666",
  #    "gender_id": 1,
  #    "email": "no@email.com",
  #    "addresses": [
  #    {
  #        "line1": "123 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225,
  #    "is_primary": true
  # }
  # ],
  #    "phones": [
  #    {
  #        "phone_number": "5552221212",
  #    "phone_type_id": "3",
  #    "extension": "3433"
  # },
  #    {
  #        "phone_number": "3332221212",
  #    "phone_type_id": "2",
  #    "extension": "5566",
  #    "is_primary": true
  # }
  # ]
  # }
  # },
  #    "primary_insurance": {
  #    "insured_person_relationship_type": "OTHER",
  #    "insurance_policy_type_id": "1",
  #    "member_number": "M4847575754",
  #    "policy_id": 232455,
  #    "effective_date": "2010-03-04",
  #    "type": "Other",
  #    "group_name": "Special Group",
  #    "payer": {
  #    "id": "1",
  #    "name": "BCBS Mass",
  #    "name2": "Boston Branch",
  #    "address": {
  #    "line1": "123 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225
  # },
  #    "phone": "3334445555"
  # },
  #    "insured": {
  #    "first_name": "bob",
  #    "last_name": "smith",
  #    "middle_initial": "A",
  #    "date_of_birth": "2000-08-09",
  #    "ssn": "333-55-6666",
  #    "gender_id": 1,
  #    "email": "no@email.com",
  #    "addresses": [
  #    {
  #        "line1": "123 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225,
  #    "is_primary": true
  # }
  # ],
  #    "phones": [
  #    {
  #        "phone_number": "5552221212",
  #    "phone_type_id": "3",
  #    "extension": "3433"
  # },
  #    {
  #        "phone_number": "3332221212",
  #    "phone_type_id": "2",
  #    "extension": "5566",
  #    "is_primary": true
  # }
  # ]
  # }
  # },
  #    "secondary_insurance": {
  #    "insured_person_relationship_type": "SELF",
  #    "insurance_policy_type_id": "2",
  #    "member_number": "M4335754",
  #    "policy_id": 2455,
  #    "group_name": "Special Group 004",
  #    "effective_date": "2010-07-04",
  #    "type": "Self",
  #    "payer": {
  #    "id": "2",
  #    "name": "Aetna",
  #    "name2": "Grove Dist",
  #    "address": {
  #    "line1": "127 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225
  # },
  #    "phone": "3334488555"
  # },
  #    "insured": {
  #    "first_name": "bob",
  #    "last_name": "smith",
  #    "middle_initial": "A",
  #    "date_of_birth": "2000-08-09",
  #    "ssn": "333-55-6666",
  #    "gender_id": 1,
  #    "email": "no@email.com",
  #    "addresses": [
  #    {
  #        "line1": "124 fake st",
  #    "line2": "apt3",
  #    "city": "newton",
  #    "state_id": 22,
  #    "zip_code": "07488",
  #    "country_id": 225,
  #    "is_primary": true
  # }
  # ]
  # }
  # }
  # }
  # }


  # server action: Return patient id
  # server response:
  # --> if success: 201, with patient id
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/patients/createfullpatient?' do

    # Validate the input parameters
    request_body = get_request_JSON
    patient_json = request_body["patient_data"]
    insurance_json = request_body["insurance_information"] if request_body["insurance_information"]

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients.json?token='
    urlpatient << CGI::escape(params[:authentication])

    begin
      response = RestClient.post(urlpatient, patient_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Patient Creation Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    if request_body["insurance_information"]
      returnedBody = JSON.parse(response.body)
      patient_id = returnedBody["patient"]["external_id"]

      # http://localservices.carecloud.local:3000/business_entity/12/patients/2/createextended.json?token=
      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'business_entity/'
      urlpatient << business_entity
      urlpatient << '/patients/'
      urlpatient << patient_id
      urlpatient << '/createextended.json?token='
      urlpatient << CGI::escape(params[:authentication])

      begin
        response = RestClient.put(urlpatient, insurance_json, :content_type => :json)
      rescue => e
        begin
          errmsg = "Retrieving Patient Data Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      external_patient = returnedBody["patient"]["external_id"]
      the_response_hash = {:patient => external_patient.to_s}
      #Client Related: Return just patient id
      body(the_response_hash.to_json)
      status HTTP_CREATED
    else
      returnedBody = JSON.parse(response.body)
      value = returnedBody["patient"]["external_id"]
      the_response_hash = {:patient => value.to_s}
      #Client Related: Return just patient id
      body(the_response_hash.to_json)
      status HTTP_CREATED
    end
  end

  #  delete patient by id
  #
  # DELETE /v1/patients/<patientid#>?authentication=<authenticationToken>
  #
  # Params definition
  # :patientid     - the patient identifier number
  #    (ex: patient-1234)
  #
  # server action: return status information
  # server response:
  # --> if patient deleted: 200, patient id deleted
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  delete '/v1/patients/:patientid?' do

    # Validate the input parameters
    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]

    #format to what the devservice needs
    patientid.slice!(/^patient-/)

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    ## if external id, lookup internal
    patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)

    #DELETE /businesses/:business_entity_id/patients/:id(.:format) {:action=>"destroy", :controller=>"patients"}
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << patientid
    urlpatient << '.json?token='
    urlpatient << CGI::escape(pass_in_token)

    begin
      response = RestClient.delete(urlpatient)
    rescue => e
      begin
        errmsg = "Delete Patient Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body('{"success":"Patient has been deleted"}')

    status HTTP_OK

  end


  get '/v1/patients/getbatcherrors/:batch_id?' do
    pass_in_token = CGI::unescape(params[:authentication])
    #business_entity = get_business_entity(pass_in_token)
    results = CareCloud::BatchErrors.find_by_id(params[:batch_id])
    #validatation: Make sure the Business has correct access to the data.
    #if results.business_entity_id.to_s == business_entity and !results.nil?
      body(results.to_json(:except => :uuid))
      status HTTP_OK
    #else
      #api_svc_halt 500, '{"error": "An error Has Occurred, Business Entity does not match."}'
    #end
  end

  post '/v1/patients/business_entity/:business_entity_id/createBatch?' do
    request_body = get_request_JSON
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = params[:business_entity_id]
    data = Array.new
    request_body['data'].each do |a|
      data << a
    end
    #validatation: Make sure the Business has correct access to the data.
    create_batch = CareCloud::BatchUploadData.create(:statuscode => 'Active',
                                                     :is_processed => 'false',
                                                     :batch_type => 'Create Patient Batch',
                                                     :business_entity_id => business_entity.to_s,
                                                     :json_data => data)
    if create_batch
      return_batch_id = {:Success => "Please Check Back in 24 hours for Results of upload: Batch ID: #{create_batch.id}"}
      body(return_batch_id.to_json)
      status HTTP_OK
    else
      api_svc_halt 500, '{"error": "An error Has Occurred, Business Entity does not match."}'
    end
  end

  post '/v2/patients/createfullpatient?' do
    # Validate the input parameters
    # store errors
    # add id and patient name to success
    # success = []
    request_body = get_request_JSON
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    index_counter = 0
    errors =  Array.new
    success = Array.new
    request_body['batch_import'].each do |pc|
      patient_json = pc["patient_data"]
      if pc["patient_data"].nil?
        pc["error"] = JSON.parse('{"error":"Patient_data is key required in JSON"}')
        errors.push(pc)
        index_counter += 1
        next if index_counter < request_body['batch_import'].size
        #TODO return logs.
        value = return_results(success, errors)  if index_counter >= request_body['batch_import'].size
        if value
          begin
            batch_error = CareCloud::BatchErrors.create(:statuscode => 'Active',
                                                        :is_reprocess => 'false',
                                                        :request_method => "Create Patient Batch",
                                                        :business_entity_id => business_entity.to_s,
                                                        :error_msgs => errors,
                                                        :error_code => "Errors",
                                                        :error_count => errors.size.to_s)
            update_batch_number(params[:reprocess_batch_id]) if params[:reprocess_batch_id]
            value_hash = {:errors => errors.length.to_s, :success => success.length.to_s, :batch_import_id => batch_error.id, :patients_processed => success }
            body(value_hash.to_json)
            status HTTP_OK
            break
          rescue
          end
        end
      end

      insurance_json = pc["insurance_information"] if pc["insurance_information"]
      pass_in_token = CGI::unescape(params[:authentication])
      business_entity = get_business_entity(pass_in_token)

      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity
      urlpatient << '/patients.json?token='
      urlpatient << CGI::escape(params[:authentication])

      begin
        response = RestClient.post(urlpatient, patient_json.to_json, :content_type => :json)
        if response.code == 201
          success_value = JSON.parse(response.body)
          success.push("{Patient Name: #{success_value['patient']['first_name']} #{success_value['patient']['last_name']}, Patient ID: #{success_value['patient']['external_id']}}")
          index_counter += 1 if insurance_json.blank?
        end
      rescue => e
        begin
          errmsg = "Patient Creation Failed - #{e.message}"
          pc["error"] = errmsg
          errors.push(pc)
          index_counter += 1
          next if index_counter < request_body['batch_import'].size
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end
      if pc["insurance_information"]
        pc = JSON.parse(response.body)
        patient_id = pc["patient"]["external_id"]

        # http://localservices.carecloud.local:3000/business_entity/12/patients/2/createextended.json?token=
        urlpatient = ''
        urlpatient << API_SVC_URL
        urlpatient << 'business_entity/'
        urlpatient << business_entity
        urlpatient << '/patients/'
        urlpatient << patient_id
        urlpatient << '/createextended.json?token='
        urlpatient << CGI::escape(params[:authentication])

        begin
          response = RestClient.put(urlpatient, insurance_json.to_json, :content_type => :json)
          if response.code == 201
            success_value = JSON.parse(response.body)
            success.push("{Patient Name: #{success_value['patient']['first_name']} #{success_value['patient']['last_name']}, Patient ID: #{success_value['patient']['external_id']}}")
            index_counter += 1
          end
        rescue => e
          begin
            errors << pc.to_json
            errmsg = "Retrieving Patient Data Failed - #{e.message}"
            next if index_counter < request_body['batch_import'].size
            index_counter += 1
            value = return_results(success, errors)  if index_counter >= request_body['batch_import'].size
            if value
              batch_error = CareCloud::BatchErrors.create(:statuscode => 'Active',
                                                          :is_reprocess => 'false',
                                                          :request_method => "Create Patient Batch",
                                                          :business_entity_id => business_entity.to_s,
                                                          :error_msgs => errors,
                                                          :error_code => "Errors",
                                                          :error_count => errors.size.to_s)
              update_batch_number(params[:reprocess_batch_id]) if params[:reprocess_batch_id]
              value_hash = {:errors => errors.length.to_s, :success => success.length.to_s, :error_data => errors, :patients_processed => success }
              body(value_hash.to_json)
              status HTTP_OK
              break
            end
          rescue
            api_svc_halt HTTP_INTERNAL_ERROR, errmsg
          end
        end
      end
    end
    value_hash = {:errors => errors.length.to_s, :success => success.length.to_s, :error_data => errors, :patients_processed => success }
    body(value_hash.to_json)
    status HTTP_OK
  end

  #  update a patient
  #
  #  PUT /v1/patients/<patientid#>?authentication=<authenticationToken>
  #
  # Params definition
  # JSON:
  #     {
  #     "patient": {
  #         "first_name": "bob",
  #         "last_name": "smith",
  #         "middle_initial": "E",
  #         "email": "no@email.com",
  #         "prefix": "mr",
  #         "suffix": "jr",
  #         "ssn": "123-45-6789",
  #         "gender_id": "1",
  #         "date_of_birth": "2000-03-12"
  #     },
  #     "addresses": {
  #         "line1": "123 fake st",
  #         "line2": "apt3",
  #         "city": "newton",
  #         "state_code": "ma",
  #         "zip_code": "07488",
  #         "county_name": "suffolk",
  #         "latitude": "",
  #         "longitude": "",
  #         "country_id": "225"
  #     },
  #     "phones": [
  #         {
  #             "phone_number": "5552221212",
  #             "phone_type_id": "3",
  #             "extension": "3433"
  #         },
  #         {
  #             "phone_number": "3332221212",
  #             "phone_type_id": "2",
  #             "extension": "5566"
  #         }
  #     ]
  # }
  #
  # Input requirements
  #   - date_of_birth: must be a valid Date. Hint: YYYY-MM-DD, YYYY/MM/DD, YYYYMMDD
  #   - gender ids:
  #       id;description;code
  #       3;"Unknown";"U"
  #       2;"Female";"F"
  #       1;"Male";"M"
  #   - country_id:
  #       225;United States
  #   - phone_type_id:
  #       id;description;code
  #       1;"Business";"B"
  #       11;"Main";"M"
  #       9;"Fax";"F"
  #       7;"TollFree";"TF"
  #       6;"VOIP";"V"
  #       5;"Skype";"S"
  #       4;"Pager";"P"
  #       3;"Cell";"C"
  #       2;"Home";"H"
  #       8;"SMS";"SMS"
  #       10;"State 800";"S800"
  #       12;"National 800";"N800"
  #
  # server action: Return patient id
  # server response:
  # --> if success: 200, with patient id
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  put '/v1/patients/:patientid?' do


    ## Validate the input parameters
    request_body = get_request_JSON

    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]

    #format to what the devservice needs
    patientid.slice!(/^patient-/)

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    ## if external id, lookup internal
    patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)


    # PUT    /businesses/:business_entity_id/patients/:id(.:format) {:action=>"update", :controller=>"patients"}
    ## PUT http://localservices.carecloud.local:3000/businesses/1/patients/4751459.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << patientid
    urlpatient << '.json?token='
    urlpatient << CGI::escape(pass_in_token)

    #LOG.debug("url for patient update: " + urlpatient)

    begin
      response = RestClient.put(urlpatient, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Update to Patient Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    parsed["patient"]["id"] = parsed["patient"]["external_id"]
    body(parsed.to_json)

    status HTTP_OK

  end


  #  update a patient by legacy id - helper method for interface
  #
  #  PUT /v1/patients/legacy/<patientid#>?authentication=<authenticationToken>
  #
  # Params definition
  # JSON:
  #     {
  #     "patient": {
  #         "first_name": "bob",
  #         "last_name": "smith",
  #         "middle_initial": "E",
  #         "email": "no@email.com",
  #         "prefix": "mr",
  #         "suffix": "jr",
  #         "ssn": "123-45-6789",
  #         "gender_id": "1",
  #         "date_of_birth": "2000-03-12"
  #     },
  #     "addresses": {
  #         "line1": "123 fake st",
  #         "line2": "apt3",
  #         "city": "newton",
  #         "state_code": "ma",
  #         "zip_code": "07488",
  #         "county_name": "suffolk",
  #         "latitude": "",
  #         "longitude": "",
  #         "country_id": "225"
  #     },
  #     "phones": [
  #         {
  #             "phone_number": "5552221212",
  #             "phone_type_id": "3",
  #             "extension": "3433"
  #         },
  #         {
  #             "phone_number": "3332221212",
  #             "phone_type_id": "2",
  #             "extension": "5566"
  #         }
  #     ]
  # }
  #
  # Input requirements
  #   - date_of_birth: must be a valid Date. Hint: YYYY-MM-DD, YYYY/MM/DD, YYYYMMDD
  #   - gender ids:
  #       id;description;code
  #       3;"Unknown";"U"
  #       2;"Female";"F"
  #       1;"Male";"M"
  #   - country_id:
  #       225;United States
  #   - phone_type_id:
  #       id;description;code
  #       1;"Business";"B"
  #       11;"Main";"M"
  #       9;"Fax";"F"
  #       7;"TollFree";"TF"
  #       6;"VOIP";"V"
  #       5;"Skype";"S"
  #       4;"Pager";"P"
  #       3;"Cell";"C"
  #       2;"Home";"H"
  #       8;"SMS";"SMS"
  #       10;"State 800";"S800"
  #       12;"National 800";"N800"
  #
  # server action: Return patient id
  # server response:
  # --> if success: 200, with patient id
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  put '/v1/patients/legacy/:patientid?' do


    ## Validate the input parameters
    request_body = get_request_JSON

    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]

    #format to what the devservice needs
    patientid.slice!(/^patient-/)

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

    ## this will be the legacy id from the interface. Get the internal id for the update

    ## http://localservices.carecloud.local:3000/businesses/1/patients/1304202/legacyid.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << patientid
    urlpatient << '/legacyid.json?token='
    urlpatient << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Cannot locate patient by legacy id - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    internal_patient_id = parsed["patient"]["id"]

    #LOG.debug(internal_patient_id)

    # PUT    /businesses/:business_entity_id/patients/:id(.:format) {:action=>"update", :controller=>"patients"}
    ## PUT http://localservices.carecloud.local:3000/businesses/1/patients/4751459.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << internal_patient_id.to_s
    urlpatient << '.json?token='
    urlpatient << CGI::escape(pass_in_token)

    begin
      response = RestClient.put(urlpatient, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Cannot update patient by legacy id - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)

    parsed["patient"]["id"] = parsed["patient"]["external_id"]

    body(parsed.to_json)

    status HTTP_OK
  end


  # search for patient
  # currently this implementation is incredibly basic.
  # in the rails app it builds a search against first name and last name, filtering by business entity
  # we need to add other criteria
  #
  # the rails app accepts "search" and "limit". Search is a whitespace separated token of criteria

  # {
  #    "limit": 5,
  #    "search": [
  #    {
  #        "term": "test"
  #    },
  #    {
  #        "term": "smith"
  #    }
  #    ]
  # }
  post '/v1/patients/search?' do

    ## Validate the input parameters
    request_body = get_request_JSON

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

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
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/search.json?token='
    urlpatient << CGI::escape(pass_in_token)
    urlpatient << '&limit='
    urlpatient << search_limit
    urlpatient << '&search='
    urlpatient << CGI::escape(search_data)

    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Search Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = JSON.parse(response.body)
    returnedBody["patients"].each do |x|
    x["id"] = x["external_id"]
    end
    body(returnedBody.to_json)
    status HTTP_OK


  end


  #  get gender information
  #
  # GET /v1/person/genders?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return gender information for authenticated user
  # server response:
  # --> if data found: 200, with gender data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/genders?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_genders.json?token='
    urlreference << CGI::escape(pass_in_token)

    #LOG.debug("url for genders: " + urlreference)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Gender Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end


  #  Get Insurance Profiles
  #
  # GET /v1/person/insuranceprofiles/:patient_id?authentication=<authenticationToken>
  #
  # Params definition
  # :patient_id  - will be based on patient
  #
  # server action: Return insurance profile information for patient
  # server response:
  # --> if data found: 200, with insurance data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/insuranceprofiles/:patient_id?' do
    validate_param(params[:patient_id], PATIENT_REGEX, PATIENT_MAX_LEN)
    api_svc_halt HTTP_FORBIDDEN if params[:authentication] == nil
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patient_id = params[:patient_id]
    patient_id.slice!(/^patient-/)
    patientid = get_internal_patient_id(patient_id, business_entity, pass_in_token)


    #http://localservices.carecloud.local:3000/businesses/1234/insurance_profiles/list_by_patient.json?token=
    urlinsurance = ''
    urlinsurance << API_SVC_URL
    urlinsurance << 'businesses/'
    urlinsurance << business_entity
    urlinsurance << '/insuranceprofiles/'
    urlinsurance << patientid
    urlinsurance << '.json?token='
    urlinsurance << CGI::escape(pass_in_token)

    #LOG.debug("url for genders: " + urlreference)

    begin
      response = RestClient.get(urlinsurance)
    rescue => e
      begin
        errmsg = "Retrieving Patient Insurance Profiles Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    insurances = JSON.parse(response.body)
    filtered_data = []
    insurances.each do |insurance|
      temp = {}
      temp['id'] = insurance['insurance_profile']['id']
      temp['is_self_pay'] = insurance['insurance_profile']['is_self_pay']
      temp['name'] = insurance['insurance_profile']['name']
      filtered_data << temp
    end
    body(filtered_data.to_json)
    status HTTP_OK
  end


  #  get ethnicity information
  #
  # GET /v1/person/ethnicities?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return ethnicities information for authenticated user
  # server response:
  # --> if data found: 200, with ethnicities data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/ethnicities?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_ethnicities.json?token='
    urlreference << CGI::escape(pass_in_token)

    #LOG.debug("url for ethnicities: " + urlreference)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Ethnicity Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end

  #  get languge information
  #
  # GET /v1/person/languges?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return languge information for authenticated user
  # server response:
  # --> if data found: 200, with languge data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/languages?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_languages.json?token='
    urlreference << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Languages Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end

  #  get races information
  #
  # GET /v1/person/races?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return races information for authenticated user
  # server response:
  # --> if data found: 200, with races data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/races?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_races.json?token='
    urlreference << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Races Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end

  #  get maritalstatuses information
  #
  # GET /v1/person/maritalstatuses?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return maritalstatuses information for authenticated user
  # server response:
  # --> if data found: 200, with maritalstatuses data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/maritalstatuses?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_marital_statuses.json?token='
    urlreference << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Maritalstatuses Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end


  #  get religions information
  #
  # GET /v1/person/religions?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return religions information for authenticated user
  # server response:
  # --> if data found: 200, with religions data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/religions?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_religions.json?token='
    urlreference << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Religions Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK
  end

  #  get state information
  #
  # GET /v1/person/states?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return state information for authenticated user
  # server response:
  # --> if data found: 200, with state data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/states?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/addresses/list_all_states.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'addresses/list_all_states.json?token='
    urlreference << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient States Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end

  #  get employmentstatuses information
  #
  # GET /v1/person/employmentstatuses?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return employmentstatuses information for authenticated user
  # server response:
  # --> if data found: 200, with employmentstatuses data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/person/employmentstatuses?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
    urlreference = ''
    urlreference << API_SVC_URL
    urlreference << 'people/list_all_employment_statuses.json?token='
    urlreference << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlreference)
    rescue => e
      begin
        errmsg = "Retrieving Patient Employmentstatuses Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK
  end

  # http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
  #   get :list_all_phone_types
  #   get :list_all_employment_statuses


  #  register for patient notifications
  #
  # POST /v1/patient/register?authentication=<authenticationToken>
  #
  # Params definition
  # :notification_active  - flag to indicate if the callback should be made
  # :notification_callback_url - URL address to make the callback to when appointment changes
  #
  # {
  #     "notification_active": true,
  #     "notification_callback_url": "https://www.here.com"
  # }
  # server action: Return callback information
  # server response:
  # --> if registered successfully: 200, with callback data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/patient/register?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    # Validate the input parameters
    request_body = get_request_JSON

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)
    #business_entity = 1

    ## add business entity to the request
    request_body['business_entity_id'] = business_entity
    request_body['notification_type'] = 1

    ## register callback url
    #LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlptreg = ''
    urlptreg << API_SVC_URL
    urlptreg << 'notification_callbacks.json?token='
    urlptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.post(urlptreg , request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Updating Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_CREATED

  end

  #  update register for patient notifications
  #
  # PUT /v1/patient/register?authentication=<authenticationToken>
  #
  # Params definition
  # :id - the register callback id
  # :notification_active  - flag to indicate if the callback should be made
  # :notification_callback_url - URL address to make the callback to when patient changes
  #
  # {
  #     "id" : 3343434,
  #     "notification_active": true,
  #     "notification_callback_url": "https://www.here.com"
  # }
  # server action: Return callback information
  # server response:
  # --> if registered successfully: 200, with callback data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  put '/v1/patient/register?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    # Validate the input parameters
    request_body = get_request_JSON

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)
    #business_entity = 1

    callbackid = request_body['id']

    ## add business entity to the request
    request_body['business_entity_id'] = business_entity
    request_body['notification_type'] = 1

    ## register callback url
    #LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlptreg = ''
    urlptreg << API_SVC_URL
    urlptreg << 'notification_callbacks/'
    urlptreg << callbackid
    urlptreg << '.json?token='
    urlptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.put(urlptreg , request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Updating Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    returnedBody = response.body

    body(returnedBody)

    status HTTP_OK

  end

  #  delete register for patient notifications
  #
  # DELETE /v1/patient/register?authentication=<authenticationToken>
  #
  # Params definition
  # :id - the register callback id
  # :notification_active  - flag to indicate if the callback should be made
  # :notification_callback_url - URL address to make the callback to when patient changes
  #
  # {
  #     "id" : 3343434,
  #     "notification_active": true,
  #     "notification_callback_url": "https://www.here.com"
  # }
  # server action: Return callback information
  # server response:
  # --> if registered deleted successfully: 200, with callback data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  delete '/v1/patient/register?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    # Validate the input parameters
    request_body = get_request_JSON

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)
    #business_entity = 1

    callbackid = request_body['id']

    ## add business entity to the request
    request_body['business_entity_id'] = business_entity
    request_body['notification_type'] = 1

    ## register callback url
    #LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlptreg = ''
    urlptreg << API_SVC_URL
    urlptreg << 'notification_callbacks/'
    urlptreg << callbackid
    urlptreg << '.json?token='
    urlptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.delete(urlptreg)
    rescue => e
      begin
        errmsg = "Deleting Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body('{"success":"Patient has been deleted"}')

    status HTTP_OK

  end


  #  update a patient extended information
  #
  #  PUT /v1/patientsextended/<patientid#>?authentication=<authenticationToken>
  #
  # Params definition
  # JSON:
  # {
  #     "insurance_profile": {
  #         "responsible_party_relationship": "OTHER",
  #         "is_default": true,
  #         "responsible_party": {
  #             "first_name": "bob",
  #             "last_name": "lee",
  #             "middle_initial": "A",
  #             "date_of_birth": "2000-08-09",
  #             "ssn": "333-55-6666",
  #             "gender_id": 1,
  #             "email": "no@email.com",
  #             "addresses": [
  #                 {
  #                     "line1": "123 fake st",
  #                     "line2": "apt3",
  #                     "city": "newton",
  #                     "state_id": 22,
  #                     "zip_code": "07488",
  #                     "country_id": 225,
  #                     "is_primary": true
  #                 }
  #             ],
  #             "phones": [
  #                 {
  #                     "phone_number": "5552221212",
  #                     "phone_type_id": "3",
  #                     "extension": "3433"
  #                 },
  #                 {
  #                     "phone_number": "3332221212",
  #                     "phone_type_id": "2",
  #                     "extension": "5566",
  #                     "is_primary": true
  #                 }
  #             ]
  #         }
  #     },
  #     "primary_insurance": {
  #         "insured_person_relationship_type": "OTHER",
  #         "insurance_policy_type_id": "1",
  #         "member_number": "M4847575754",
  #         "policy_id": 232455,
  #         "effective_date": "2010-03-04",
  #         "type": "Other",
  #         "group_name": "Special Group",
  #         "payer": {
  #             "id": "1",
  #             "name": "BCBS Mass",
  #             "name2": "Boston Branch",
  #             "address": {
  #                 "line1": "123 fake st",
  #                 "line2": "apt3",
  #                 "city": "newton",
  #                 "state_id": 22,
  #                 "zip_code": "07488",
  #                 "country_id": 225
  #             },
  #             "phone": "3334445555"
  #         },
  #         "insured": {
  #             "first_name": "bob",
  #             "last_name": "smith",
  #             "middle_initial": "A",
  #             "date_of_birth": "2000-08-09",
  #             "ssn": "333-55-6666",
  #             "gender_id": 1,
  #             "email": "no@email.com",
  #             "addresses": [
  #                 {
  #                     "line1": "123 fake st",
  #                     "line2": "apt3",
  #                     "city": "newton",
  #                     "state_id": 22,
  #                     "zip_code": "07488",
  #                     "country_id": 225,
  #                     "is_primary": true
  #                 }
  #             ],
  #             "phones": [
  #                 {
  #                     "phone_number": "5552221212",
  #                     "phone_type_id": "3",
  #                     "extension": "3433"
  #                 },
  #                 {
  #                     "phone_number": "3332221212",
  #                     "phone_type_id": "2",
  #                     "extension": "5566",
  #                     "is_primary": true
  #                 }
  #             ]
  #         }
  #     },
  #     "secondary_insurance": {
  #         "insured_person_relationship_type": "SELF",
  #         "insurance_policy_type_id": "2",
  #         "member_number": "M4335754",
  #         "policy_id": 2455,
  #         "group_name": "Special Group 004",
  #         "effective_date": "2010-07-04",
  #         "type": "Self",
  #         "payer": {
  #             "id": "2",
  #             "name": "Aetna",
  #             "name2": "Grove Dist",
  #             "address": {
  #                 "line1": "127 fake st",
  #                 "line2": "apt3",
  #                 "city": "newton",
  #                 "state_id": 22,
  #                 "zip_code": "07488",
  #                 "country_id": 225
  #             },
  #             "phone": "3334488555"
  #         },
  #         "insured": {
  #             "first_name": "bob",
  #             "last_name": "smith",
  #             "middle_initial": "A",
  #             "date_of_birth": "2000-08-09",
  #             "ssn": "333-55-6666",
  #             "gender_id": 1,
  #             "email": "no@email.com",
  #             "addresses": [
  #                 {
  #                     "line1": "124 fake st",
  #                     "line2": "apt3",
  #                     "city": "newton",
  #                     "state_id": 22,
  #                     "zip_code": "07488",
  #                     "country_id": 225,
  #                     "is_primary": true
  #                 }
  #             ]
  #         }
  #     }
  # }
  # EOR
  # server action: Return patient id
  # server response:
  # --> if success: 200, with patient id
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  put '/v1/patientsextended/:patientid?' do

    ## Validate the input parameters
    request_body = get_request_JSON
    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]
    #format to what the devservice needs
    patientid.slice!(/^patient-/)
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity_id = get_business_entity(pass_in_token)

    # http://localservices.carecloud.local:3000/business_entity/12/patients/2/createextended.json?token=
    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'business_entity/'
    urlpatient << business_entity_id
    urlpatient << '/patients/'
    urlpatient << patientid
    urlpatient << '/createextended.json?token='
    urlpatient << CGI::escape(params[:authentication])

    begin
      response = RestClient.put(urlpatient, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Retrieving Patient Data Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    returned_value = parsed["patient"]["external_id"]
    the_response_hash = {:patient => returned_value.to_s}
    body(the_response_hash.to_json)

    status HTTP_OK
  end


  private
  def get_patient_with_preference_settings(patient, patient_preference)
    patient["signature_source_id"] = patient["signature_source_id"].nil? ? patient_preference["default_signature_source_id"] : patient["signature_source_id"]
    patient["release_of_information_source_id"] = patient["release_of_information_source_id"].nil? ? patient_preference["default_release_of_information_source_id"] : patient["release_of_information_source_id"]
    patient["provider_assignment_indicator_id"] = patient["provider_assignment_indicator_id"].nil? ? patient_preference["default_provider_assignment_indicator_id"] : patient["provider_assignment_indicator_id"]
    return patient
  end

  def return_results(success, errors)
    value = Array.new
    value.push(errors) if errors
    value.push(success) if success
    return value
    #TODO Return Success and Errors
  end


end
