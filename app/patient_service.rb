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

        business_entity = get_business_entity(params[:authentication])
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
            urlpatient << URI::encode(params[:authentication])

        else

            urlpatient = ''
            urlpatient << API_SVC_URL
            urlpatient << 'businesses/'
            urlpatient << business_entity
            urlpatient << '/patients/'
            urlpatient << patientid
            urlpatient << '/externalid.json?token='
            urlpatient << URI::encode(params[:authentication])


        end

        LOG.debug("url for patient: " + urlpatient)

		resp = generate_http_request(urlpatient, "", "", "GET")

		LOG.debug(resp.body)

        response_code = map_response(resp.code)

        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                parsed["patient"]["id"] = parsed["patient"]["external_id"]

                body(parsed.to_s)
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

                body(returned_value.to_s)
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

        business_entity = get_business_entity(params[:authentication])
        LOG.debug(business_entity)

        ## if external id, lookup internal
        if !is_this_numeric(patientid)

            urlpatient = ''
            urlpatient << API_SVC_URL
            urlpatient << 'businesses/'
            urlpatient << business_entity
            urlpatient << '/patients/'
            urlpatient << patientid
            urlpatient << '/externalid.json?token='
            urlpatient << URI::encode(params[:authentication])

            LOG.debug("url for patient: " + urlpatient)

            resp = generate_http_request(urlpatient, "", "", "GET")

            LOG.debug(resp.body)

            response_code = map_response(resp.code)
            if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                patientid = parsed["patient"]["id"].to_s

            else
                api_svc_halt HTTP_BAD_REQUEST, '{"error":"Cannot locate patient record"}' 
            end

        end

        #DELETE /businesses/:business_entity_id/patients/:id(.:format) {:action=>"destroy", :controller=>"patients"}
        urlpatient = ''
        urlpatient << API_SVC_URL
        urlpatient << 'businesses/'
        urlpatient << business_entity
        urlpatient << '/patients/'
        urlpatient << patientid
        urlpatient << '.json?token='
        urlpatient << URI::encode(params[:authentication])

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

        business_entity = get_business_entity(params[:authentication])
        LOG.debug(business_entity)


        ## if external id, lookup internal
        if !is_this_numeric(patientid)

            urlpatient = ''
            urlpatient << API_SVC_URL
            urlpatient << 'businesses/'
            urlpatient << business_entity
            urlpatient << '/patients/'
            urlpatient << patientid
            urlpatient << '/externalid.json?token='
            urlpatient << URI::encode(params[:authentication])

            LOG.debug("url for patient: " + urlpatient)

            resp = generate_http_request(urlpatient, "", "", "GET")

            LOG.debug(resp.body)

            response_code = map_response(resp.code)
            if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                patientid = parsed["patient"]["id"].to_s

            else
                api_svc_halt HTTP_BAD_REQUEST, '{"error":"Cannot locate patient record"}' 
            end

        end


        # PUT    /businesses/:business_entity_id/patients/:id(.:format) {:action=>"update", :controller=>"patients"}
        ## PUT http://localservices.carecloud.local:3000/businesses/1/patients/4751459.json?token=
        urlpatient = ''
        urlpatient << API_SVC_URL
        urlpatient << 'businesses/'
        urlpatient << business_entity
        urlpatient << '/patients/'
        urlpatient << patientid
        urlpatient << '.json?token='
        urlpatient << URI::encode(params[:authentication])

        LOG.debug("url for patient update: " + urlpatient)

        resp = generate_http_request(urlpatient, "", request_body.to_json, "PUT")

        response_code = map_response(resp.code)

        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                parsed["patient"]["id"] = parsed["patient"]["external_id"]

                body(parsed.to_s)
        else
            body(resp.body)
        end

        status response_code

    end

    #todo - search patient


end