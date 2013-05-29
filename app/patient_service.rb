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
        patientid = params[:patientid]

        #format to what the devservice needs
        patientid.slice!(/^patient-/)

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        business_entity = get_business_entity(pass_in_token)
        LOG.debug(business_entity)

        ## if the patient id is all numeric call getById
        if is_this_numeric(patientid)

            urlpatient = ''
            urlpatient << API_SVC_URL
            urlpatient << 'businesses/'
            urlpatient << business_entity
            urlpatient << '/patients/'
            urlpatient << patientid
            urlpatient << '.json?token='
            urlpatient << URI::encode(pass_in_token)

        else

            urlpatient = ''
            urlpatient << API_SVC_URL
            urlpatient << 'businesses/'
            urlpatient << business_entity
            urlpatient << '/patients/'
            urlpatient << patientid
            urlpatient << '/externalid.json?token='
            urlpatient << URI::encode(pass_in_token)


        end

        LOG.debug("url for patient: " + urlpatient)

		resp = generate_http_request(urlpatient, "", "", "GET")

		LOG.debug(resp.body)

        response_code = map_response(resp.code)

        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                parsed["patient"]["id"] = parsed["patient"]["external_id"]
                the_response_hash = { :patient => parsed.to_s}
                body(the_response_hash.to_json)
        else
            body(resp.body)
        end

        status response_code

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
        patientid = params[:patientid]

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        business_entity = get_business_entity(pass_in_token)
        
        ## http://localservices.carecloud.local:3000/businesses/1/patients/1304202/legacyid.json?token=

        urlpatient = ''
        urlpatient << API_SVC_URL
        urlpatient << 'businesses/'
        urlpatient << business_entity
        urlpatient << '/patients/'
        urlpatient << patientid
        urlpatient << '/legacyid.json?token='
        urlpatient << URI::encode(pass_in_token)


        LOG.debug("url for patient: " + urlpatient)

        resp = generate_http_request(urlpatient, "", "", "GET")

        LOG.debug(resp.body)

        response_code = map_response(resp.code)

        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                parsed["patient"]["id"] = parsed["patient"]["external_id"]
                the_response_hash = { :patient => parsed.to_s}
                body(the_response_hash.to_json)
        else
            body(resp.body)
        end

        status response_code

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

        business_entity = get_business_entity(params[:authentication])
        
        urlpatient = ''
        urlpatient << API_SVC_URL
        urlpatient << 'businesses/'
        urlpatient << business_entity
        urlpatient << '/patients.json?token='
        urlpatient << URI::encode(params[:authentication])

        LOG.debug("url for patient create: " + urlpatient)

        resp = generate_http_request(urlpatient, "", request_body.to_json, "POST")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        if response_code == HTTP_CREATED

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                returned_value = parsed["patient"]["external_id"]
                the_response_hash = { :patient => returned_value.to_s}
                body(the_response_hash.to_json)
        else
            body(resp.body)
        end

        status response_code

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
        pass_in_token = URI::decode(params[:authentication])

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
        urlpatient << URI::encode(pass_in_token)

        LOG.debug("url for patient delete: " + urlpatient)

        resp = generate_http_request(urlpatient, "", "", "DELETE")

        LOG.debug(resp.body)

        response_code = map_response(resp.code)
        if response_code == HTTP_OK
            body('{"success":"Patient has been deleted"}')
        else
            body(resp.body)
        end

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

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
        urlpatient << URI::encode(pass_in_token)

        LOG.debug("url for patient update: " + urlpatient)

        resp = generate_http_request(urlpatient, "", request_body.to_json, "PUT")

        response_code = map_response(resp.code)

        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                parsed["patient"]["id"] = parsed["patient"]["external_id"]
                the_response_hash = { :patient => parsed.to_s}
                body(the_response_hash.to_json)
        else
            body(resp.body)
        end

        status response_code

    end

    #todo - search patient

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'people/list_all_genders.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for genders: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'people/list_all_ethnicities.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for ethnicities: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'people/list_all_languages.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for languge: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'people/list_all_races.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for races: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'people/list_all_marital_statuses.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for maritalstatuses: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/people/list_all_religions.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'people/list_all_religions.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for religions: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

        #http://localservices.carecloud.local:3000/addresses/list_all_states.json?token=
        urlreference = ''
        urlreference << API_SVC_URL
        urlreference << 'addresses/list_all_states.json?token='
        urlreference << URI::encode(pass_in_token)

        LOG.debug("url for states: " + urlreference)

        resp = generate_http_request(urlreference, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

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
        pass_in_token = URI::decode(params[:authentication])

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
        urlptreg << URI::encode(pass_in_token)

        LOG.debug("url for patient register: " + urlptreg)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlptreg, "", request_body.to_json, "POST")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        body(resp.body)

        status response_code

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
        pass_in_token = URI::decode(params[:authentication])

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
        urlptreg << URI::encode(pass_in_token)

        LOG.debug("url for appointment register: " + urlptreg)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlptreg, "", request_body.to_json, "PUT")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        body(resp.body)

        status response_code

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
        pass_in_token = URI::decode(params[:authentication])

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
        urlptreg << URI::encode(pass_in_token)

        LOG.debug("url for appointment register: " + urlptreg)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlptreg, "", request_body.to_json, "DELETE")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        body(resp.body)

        status response_code

    end


    ## create extended
    ## insurance_profile
#     {
#     "insurance_profile": {
#         "business_entity_id": 1,
#         "responsible_party_relationship": "FATHER",
#         "is_default": true,
#         "responsible_party": {
#           "first_name": "bob",
#           "last_name": "smith",
#           "middle_initial": "A",
#           "date_of_birth": "2000-08-09",
#           "ssn": "333-55-6666",
#           "gender_id": 1,
#           "email": "no@email.com",
#           "addresses": [
#              {
#                  "line1": "123 fake st",
#                  "line2": "apt3",
#                  "city": "newton",
#                  "state_id": 22,
#                  "zip_code": "07488",
#                  "country_id": 225,
#                  "is_primary": true
#               }
#           ],
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
#     }
# }


# # insurance policy
# {
#     "primary_insurance": {
#         "interface_id": 1,
#         "business_entity_id": 1,
#         "insured_person_relationship_type": "SELF",
#         "member_number": "M4847575754",
#         "policy_id": 232455,
#         "effective_date": "2010-03-04",
#         "type": "SELF",
#         "payer": {
#             "id": 1,
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
#             "group_number": "G393988444",
#             "group_name": "Special Group 001",
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
#             ]
#         }
#     },
#     "secondary_insurance": {
#         "interface_id": 1,
#         "business_entity_id": 1,
#         "insured_person_relationship_type": "OTHER",
#         "member_number": "M4335754",
#         "policy_id": 2455,
#         "effective_date": "2010-07-04",
#         "type": "OTHER",
#         "payer": {
#             "id": 1,
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
#             "group_number": "G3788444",
#             "group_name": "Special Group 004",
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
#                     "line1": "123 fake st",
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


######all together

# {
#     "insurance_profile": {
#         "business_entity_id": 1,
#         "responsible_party_relationship": "FATHER", (OPTIONS: map_constants("SELF" => '18', "SPOUSE" => '01', "CHILD" => '19', "OTHER" => 'G8', "ATTORNEY" => '60'))
#         "is_default": true,
#         "responsible_party": {
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
#     "primary_insurance": {
#         "interface_id": 1,
#         "business_entity_id": 1,
#         "insured_person_relationship_type": "SELF",
#         "member_number": "M4847575754",
#         "policy_id": 232455,
#         "effective_date": "2010-03-04",
#         "type": "SELF",
#         "payer": {
#             "id": 1,
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
#             "group_number": "G393988444",
#             "group_name": "Special Group 001",
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
#             ]
#         }
#     },
#     "secondary_insurance": {
#         "interface_id": 1,
#         "business_entity_id": 1,
#         "insured_person_relationship_type": "OTHER",
#         "member_number": "M4335754",
#         "policy_id": 2455,
#         "effective_date": "2010-07-04",
#         "type": "OTHER",
#         "payer": {
#             "id": 1,
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
#             "group_number": "G3788444",
#             "group_name": "Special Group 004",
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
#                     "line1": "123 fake st",
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

end