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
    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
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

    LOG.debug(parsed)

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

    LOG.debug(parsed2)

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

    LOG.debug(parsed)

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

    LOG.debug(parsed2)

    results = []
    results << parsed
    results << parsed2

    LOG.debug(results)

    body(results.to_json)

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

    LOG.debug("Before Providers cal")

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

    LOG.debug(parsed)
    body(parsed.to_json)

    LOG.debug("good")
    status HTTP_OK


  end


  #  create a patient
  #
  #  POST /v1/patients/create?authentication=<authenticationToken>
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
  #     "addresses": [{
  #         "line1": "123 fake st",
  #         "line2": "apt3",
  #         "city": "newton",
  #         "state_id": "22",
  #         "zip_code": "07488",
  #         "county_name": "suffolk",
  #         "latitude": "",
  #         "longitude": "",
  #         "country_id": "225"
  #     }],
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
  #}
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

    getpreferences = ''
    getpreferences << API_SVC_URL
    getpreferences << 'business_entity/'
    getpreferences << business_entity
    getpreferences << '/patientpreferences.json?token='
    getpreferences << CGI::escape(params[:authentication])

    begin
      resp = RestClient.get(getpreferences)
    rescue => e
      begin
        errmsg = "Get Patient Preferences - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    LOG.debug "<<<<<<<<<<<<<<<<<<< REQUESTBODY >>>>>>>>>>>>>>>>"
    LOG.debug(request_body)

    temp = JSON.parse(resp.body)
    LOG.debug(temp)
    request_body = get_patient_with_preference_settings(request_body, temp['patient_preference'])

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients.json?token='
    urlpatient << CGI::escape(params[:authentication])

    begin
      response = RestClient.post(urlpatient, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Patient Creation Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
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
    LOG.debug(business_entity)

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
    LOG.debug(business_entity)

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

    LOG.debug("url for patient update: " + urlpatient)

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

    LOG.debug(internal_patient_id)

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

  #{
  #    "limit": 5,
  #    "search": [
  #    {
  #        "term": "test"
  #    },
  #    {
  #        "term": "smith"
  #    }
  #    ]
  #}
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
      LOG.debug(search_data)
    }

    search_limit = request_body['limit'].to_s
    #TODO: add external id to patient search
    #TODO: replace id with external id

    #business_entity_patient_search        /businesses/:business_entity_id/patients/search.:format  {:controller=>"patients", :action=>"search_by_business_entity"}
    #http://localservices.carecloud.local:3000/businesses/1/patients/search.json?token=<token>&search=test%20smith&limit=50
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
    returnedBody["patient"]["id"] = returnedBody["patient"]["external_id"]
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

    LOG.debug("url for genders: " + urlreference)

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

    LOG.debug("url for ethnicities: " + urlreference)

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
    LOG.debug(request_body)

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
    LOG.debug(request_body)

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
    LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlptreg = ''
    urlptreg << API_SVC_URL
    urlptreg << 'notification_callbacks/'
    urlptreg << callbackid
    urlptreg << '.json?token='
    urlptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.delete(urlptreg, request_body)
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
  #{
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
  #}
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
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
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

end