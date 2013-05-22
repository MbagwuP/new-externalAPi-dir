#
# File:       appointment_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base


	#  create an appointment for a patient
	#
    # POST /v1/appointment/create?authentication=<authenticationToken>
    #
    # Params definition
    # JSON
    #  {
    #     "appointment": {
    #         "start_time": "2013-04-24 10:00",
    #         "end_time": "2013-04-24 11:00",
    #         "location_id": 2,
    #         "nature_of_visit_id": 2,
    #         "provider_id": 2,
    #         "patients": [
    #             {
    #                 "id": 1819622,
    #                 "comments": "patienthasheadache"
    #             }]
    #     }
    # }
    #
    # server response:
    # --> if appointment created: 201, with appointment id returned
    # --> if not authorized: 401
    # --> if patient not found: 404
    # --> if bad request: 400
	post '/v1/appointment/create?' do

		# Validate the input parameters
        request_body = get_request_JSON

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ## muck with the request based on what internal needs
        business_entity = get_business_entity(pass_in_token)
        #business_entity = 1
        
        begin
            providerid = request_body['appointment']['provider_id']
            request_body['appointment'].delete('provider_id')
        rescue 
            api_svc_halt HTTP_BAD_REQUEST, '{"error":"Provider id must be passed in"}'
        end

        ## add business entity to the request
        request_body['appointment']['business_entity_id'] = business_entity

        ## validate the provider
        providerids = get_providers_by_business_entity(business_entity, pass_in_token)

        ## validate the request based on token
        check_for_valid_provider(providerids, providerid)

        ## retrieve the internal patient id for the request
        patientid = ''
        request_body['appointment']['patients'].each { |x| 

            patientid = x['id'].to_s
 
            LOG.debug(patientid)

            patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)

            x['id'] = patientid

            LOG.debug(patientid)
        }

        LOG.debug(request_body)

        ## http://localservices.carecloud.local:3000/providers/2/appointments.json?token=
        urlapptcrt = ''
        urlapptcrt << API_SVC_URL
        urlapptcrt << 'providers/'
        urlapptcrt << providerid.to_s
        urlapptcrt << '/appointments.json?token='
        urlapptcrt << URI::encode(pass_in_token)

        LOG.debug("url for appointment create: " + urlapptcrt)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlapptcrt, "", request_body.to_json, "POST")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        ## ruby app returns 200
        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                response_code = HTTP_CREATED                
                body(parsed['appointment']['external_id'].to_s)

        else
            body(resp.body)
        end

        status response_code

	end

    #  update an appointment for a patient
    #
    # PUT /v1/appointment/<appointmentId>?authentication=<authenticationToken>
    #
    # Params definition
    # JSON
    #  {
    #     "appointment": {
    #         "start_time": "2013-04-24 10:00",
    #         "end_time": "2013-04-24 11:00",
    #         "location_id": 2,
    #         "nature_of_visit_id": 2,
    #         "provider_id": 2,
    #         "patients": [
    #             {
    #                 "id": 1819622,
    #                 "comments": "patienthasheadache"
    #             }]
    #     }
    # }
    #
    # server action: Return appointment payload after create
    #
    # server response:
    # --> if appointment updated: 200, with appointment payload returned
    # --> if not authorized: 401
    # --> if patient not found: 404
    # --> if bad request: 400
    # NOTE: Commenting out update. The app does not currently support it (even though endpoint exists)
    # put '/v1/appointment/:appointmentid?' do

    #     ## Validate the input parameters
    #     request_body = get_request_JSON

    #     business_entity = get_business_entity(params[:authentication])
    #     LOG.debug(business_entity)

    #     begin
    #         provider_id = request_body['appointment']['provider_id']
    #         request_body['appointment'].delete('provider_id')
    #     rescue 
    #         api_svc_halt HTTP_BAD_REQUEST, '{"error":"Provider id must be passed in"}'
    #     end

    #     ## add business entity to the request
    #     request_body['appointment']['business_entity_id'] = business_entity

    #     ## /providers/:provider_id/appointments/:id(.:format)  {:action=>"update", :controller=>"provider_appointments"}
    #     urlapptupd = ''
    #     urlapptupd << API_SVC_URL
    #     urlapptupd << 'providers/'
    #     urlapptupd << provider_id.to_s
    #     urlapptupd << '/appointments/'
    #     urlapptupd << params[:appointmentid]
    #     urlapptupd << '.json?token='
    #     urlapptupd << URI::encode(params[:authentication])
    #     LOG.debug("url for appointment update: " + urlapptupd)
    #     resp = generate_http_request(urlapptupd, "", request_body.to_json, "PUT")
    #     response_code = map_response(resp.code)
    #     if response_code == HTTP_OK
    #             #parsed = JSON.parse(resp.body)
    #             #LOG.debug(parsed)
    #             body(esp.body)
    #     else
    #         body(resp.body)
    #     end
    #     status response_code
    # end

    #  delete appointment by id
    #
    # DELETE /v1/appointment/<appointmentid>?authentication=<authenticationToken>
    #
    # Params definition
    # :appointmentid     - the appointment identifier number
    #    (ex: 1234)
    #
    # :providerid - the provider identifier number
    #
    # server action: return status information
    # server response:
    # --> if appointment deleted: 200, appointment id deleted
    # --> if not authorized: 401
    # --> if not found: 404
    # --> if exception: 500
    delete '/v1/appointment/:providerid/:appointmentid?' do

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ## request parameter validation
        business_entity = get_business_entity(pass_in_token)

        providerid = params[:providerid]

         ## validate the provider
        providerids = get_providers_by_business_entity(business_entity, pass_in_token)

        ## validate the request based on token
        check_for_valid_provider(providerids, providerid)


        ## /providers/:provider_id/appointments/:id(.:format)  {:action=>"destroy", :controller=>"provider_appointments"}
        urlapptdel = ''
        urlapptdel << API_SVC_URL
        urlapptdel << 'providers/'
        urlapptdel << providerid
        urlapptdel << '/appointments/'
        urlapptdel << params[:appointmentid]
        urlapptdel << '.json?token='
        urlapptdel << URI::encode(pass_in_token)

        LOG.debug("url for appointment delete: " + urlapptdel)

        resp = generate_http_request(urlapptdel, "", "", "DELETE")

        response_code = map_response(resp.code)

        if response_code == HTTP_OK
                body(resp.body)
        else
            body(resp.body)
        end

        status response_code

    end


    ##  get appointments by provider id and date
    #
    # GET /v1/appointment/listbydate/<date>/<providerid#>?authentication=<authenticationToken>
    #
    # Params definition
    # :date - the date for the appointment.
    #    must be: YYYYMMDD
    # :providerid     - the provider identifier number
    #    (ex: provider-1234)
    #
    # server action: Return appointment information for todays date
    # server response:
    # --> if data found: 200, with array of appointment data in response body
    # --> if not authorized: 401
    # --> if provider not found: 404
    # --> if exception: 500
    get '/v1/appointment/listbydate/:date/:providerid?' do

        # Validate the input parameters
        validate_param(params[:providerid], PROVIDER_REGEX, PROVIDER_MAX_LEN)
        providerid = params[:providerid]

        validate_param(params[:date], DATE_REGEX, DATE_MAX_LEN)
        the_date = params[:date]

        #format to what the devservice needs
        providerid.slice!(/^provider-/)

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ##  get providers by business entity - check to make sure they are legit in pass in
        business_entity = get_business_entity(pass_in_token)


        providerids = get_providers_by_business_entity(business_entity, pass_in_token)

        ## validate the request based on token
        check_for_valid_provider(providerids, providerid)

        #http://devservices.carecloud.local/providers/2/appointments.json?token=&date=20130424
        urlappt = ''
        urlappt << API_SVC_URL
        urlappt << 'providers/'
        urlappt << providerid
        urlappt << '/appointments.json?token='
        urlappt << URI::encode(pass_in_token)
        urlappt << '&date='
        urlappt << the_date

        LOG.debug("url for appointment: " + urlappt)

        resp = generate_http_request(urlappt, "", "", "GET")

        response_code = map_response(resp.code)

        LOG.debug(resp.body)

        # muck with the return to take away internal ids
        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                
                # iterate the array of appointments
                parsed["appointments"].each { |x|
                    x['id'] = x['external_id']
                    x['patient']['id'] = x['patient']['external_id']
                }

                LOG.debug(parsed)
                body(parsed.to_json)
        else
            body(resp.body)
        end

        status response_code

    end

    ##  get appointments by id
    #
    # GET /v1/appointment/listbyid/<appointmentid#>?authentication=<authenticationToken>
    #
    # Params definition
    # :appointmentid - the appointment identification number
    #    (ex: abcd1234)
    #
    # server action: Return appointment information for id
    # server response:
    # --> if data found: 200, with array of appointment data in response body
    # --> if not authorized: 401
    # --> if provider not found: 404
    # --> if exception: 500
    get '/v1/appointment/listbyid/:appointmentid?' do

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        appointmentid = params[:appointmentid]

        ##  get providers by business entity - check to make sure they are legit in pass in
        business_entity = get_business_entity(pass_in_token)

        #http://devservices.carecloud.local/appointments/1/abcd93832/listbyexternalid.json?token=
        urlappt = ''
        urlappt << API_SVC_URL
        urlappt << 'appointments/'
        urlappt << business_entity
        urlappt << '/'
        urlappt << appointmentid
        urlappt << '/listbyexternalid.json?token='
        urlappt << URI::encode(pass_in_token)

        LOG.debug("url for appointment: " + urlappt)

        resp = generate_http_request(urlappt, "", "", "GET")

        response_code = map_response(resp.code)

        LOG.debug(resp.body)

        # muck with the return to take away internal ids
        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                
                # iterate the array of appointments
                 # iterate the array of appointments
                parsed.each { |x|
                    x['appointment']['id'] = x['appointment']['external_id']
                }

                LOG.debug(parsed)
                body(parsed.to_json)
        else
            body(resp.body)
        end

        status response_code


    end

    ##  get appointments by provider id
    #
    # GET /v1/appointment/listbyprovider/<providerid#>?authentication=<authenticationToken>
    #
    # Params definition
    # :providerid     - the provider identifier number
    #    (ex: provider-1234)
    #
    # server action: Return appointment information for selected provider
    # server response:
    # --> if data found: 200, with array of appointment data in response body
    # --> if not authorized: 401
    # --> if provider not found: 404
    # --> if exception: 500
    get '/v1/appointment/listbyprovider/:providerid?' do

        # Validate the input parameters
        validate_param(params[:providerid], PROVIDER_REGEX, PROVIDER_MAX_LEN)
        providerid = params[:providerid]

        #format to what the devservice needs
        providerid.slice!(/^provider-/)

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ##  get providers by business entity - check to make sure they are legit in pass in
        business_entity = get_business_entity(pass_in_token)

        providerids = get_providers_by_business_entity(business_entity, pass_in_token)

        ## validate the request based on token
        check_for_valid_provider(providerids, providerid)

        #http://devservices.carecloud.local/appointments/1/2/listbyprovider.json?token=&date=20130424
        urlappt = ''
        urlappt << API_SVC_URL
        urlappt << 'appointments/'
        urlappt << business_entity
        urlappt << '/'
        urlappt << providerid
        urlappt << '/listbyprovider.json?token='
        urlappt << URI::encode(pass_in_token)

        LOG.debug("url for appointment: " + urlappt)

        resp = generate_http_request(urlappt, "", "", "GET")

        response_code = map_response(resp.code)

        LOG.debug(resp.body)

        # muck with the return to take away internal ids
        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                
                # iterate the array of appointments
                parsed.each { |x|
                    x['appointment']['id'] = x['appointment']['external_id']
                }

                LOG.debug(parsed)
                body(parsed.to_json)
        else
            body(resp.body)
        end

        status response_code

    end


    ##  get appointments by patient id
    #
    # GET /v1/appointment/listbypatient/<patientid>?authentication=<authenticationToken>
    #
    # Params definition
    # :patientid     - the CareCloud patient identifier number
    #    (ex: patient-1234)
    #
    # server action: Return appointment information for selected patient
    # server response:
    # --> if data found: 200, with array of appointment data in response body
    # --> if not authorized: 401
    # --> if provider not found: 404
    # --> if exception: 500
    get '/v1/appointment/listbypatient/:patientid?' do

        # Validate the input parameters
        validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
        patientid = params[:patientid]

        #format to what the devservice needs
        patientid.slice!(/^patient-/)

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ##  get providers by business entity - check to make sure they are legit in pass in
        business_entity = get_business_entity(pass_in_token)

        #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424
        urlappt = ''
        urlappt << API_SVC_URL
        urlappt << 'appointments/'
        urlappt << business_entity
        urlappt << '/'
        urlappt << patientid
        urlappt << '/listbypatient.json?token='
        urlappt << URI::encode(pass_in_token)

        LOG.debug("url for appointment: " + urlappt)

        resp = generate_http_request(urlappt, "", "", "GET")

        response_code = map_response(resp.code)

        LOG.debug(resp.body)

        # muck with the return to take away internal ids
        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                
                # iterate the array of appointments
                parsed.each { |x|
                    x['appointment']['id'] = x['appointment']['external_id']
                }

                LOG.debug(parsed)
                body(parsed.to_json)
        else
            body(resp.body)
        end

        status response_code

    end

    ##  get appointments by resource id
    #
    # GET /v1/appointment/listbyresource/<resource>?authentication=<authenticationToken>
    #
    # Params definition
    # :resource     - the resource identifier number
    #    (ex: 1234)
    #
    # server action: Return appointment information for selected resource
    # server response:
    # --> if data found: 200, with array of appointment data in response body
    # --> if not authorized: 401
    # --> if provider not found: 404
    # --> if exception: 500
    get '/v1/appointment/listbyresource/:resourceid?' do

        # Validate the input parameters
        resourceid = params[:resourceid]

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ##  get providers by business entity - check to make sure they are legit in pass in
        business_entity = get_business_entity(pass_in_token)

        #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424
        urlappt = ''
        urlappt << API_SVC_URL
        urlappt << 'appointments/'
        urlappt << business_entity
        urlappt << '/'
        urlappt << resourceid
        urlappt << '/listbyresource.json?token='
        urlappt << URI::encode(pass_in_token)

        LOG.debug("url for appointment: " + urlappt)

        resp = generate_http_request(urlappt, "", "", "GET")

        response_code = map_response(resp.code)

        LOG.debug(resp.body)

        # muck with the return to take away internal ids
        if response_code == HTTP_OK

                parsed = JSON.parse(resp.body)
                
                # iterate the array of appointments
                parsed.each { |x|
                    x['appointment']['id'] = x['appointment']['external_id']
                }

                LOG.debug(parsed)
                body(parsed.to_json)
        else
            body(resp.body)
        end

        status response_code

    end
    

    #  get location information
    #
    # GET /v1/appointment/locations?authentication=<authenticationToken>
    #
    # Params definition
    # :none  - will be based on authentication
    #
    # server action: Return location information for authenticated user
    # server response:
    # --> if data found: 200, with location data payload
    # --> if not authorized: 401
    # --> if not found: 404
    # --> if exception: 500
    get '/v1/appointment/locations?' do

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        business_entity = get_business_entity(pass_in_token)
        LOG.debug(business_entity)

        #http://localservices.carecloud.local:3000/public/businesses/1/locations.json?token=
        urllocation = ''
        urllocation << API_SVC_URL
        urllocation << 'public/businesses/'
        urllocation << business_entity
        urllocation << '/locations.json?token='
        urllocation << URI::encode(pass_in_token)

        LOG.debug("url for providers: " + urllocation)

        resp = generate_http_request(urllocation, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

    end  

    #  get status information
    #
    # GET /v1/appointment/statuses?authentication=<authenticationToken>
    #
    # Params definition
    # :none  - will be based on authentication
    #
    # server action: Return status information for authenticated user
    # server response:
    # --> if data found: 200, with status data payload
    # --> if not authorized: 401
    # --> if not found: 404
    # --> if exception: 500
    get '/v1/appointment/statuses?' do

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        business_entity = get_business_entity(pass_in_token)
        LOG.debug(business_entity)

        #http://localservices.carecloud.local:3000/appointments/1/statuses.json?token=
        urllocation = ''
        urllocation << API_SVC_URL
        urllocation << 'appointments/'
        urllocation << business_entity
        urllocation << '/statuses.json?token='
        urllocation << URI::encode(pass_in_token)

        LOG.debug("url for appt sts: " + urllocation)

        resp = generate_http_request(urllocation, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

    end  


    #  get resource information
    #
    # GET /v1/appointment/resources?authentication=<authenticationToken>
    #
    # Params definition
    # :none  - will be based on authentication
    #
    # server action: Return resource information for authenticated user
    # server response:
    # --> if data found: 200, with resource data payload
    # --> if not authorized: 401
    # --> if not found: 404
    # --> if exception: 500
    get '/v1/appointment/resources?' do

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        business_entity = get_business_entity(pass_in_token)
        LOG.debug(business_entity)

        #http://localservices.carecloud.local:3000/appointments/1/resources.json?token=
        urlresource = ''
        urlresource << API_SVC_URL
        urlresource << 'appointments/'
        urlresource << business_entity
        urlresource << '/resources.json?token='
        urlresource << URI::encode(pass_in_token)

        LOG.debug("url for resources: " + urlresource)

        resp = generate_http_request(urlresource, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

    end    


    #  register for appointment notifications
    #
    # POST /v1/appointment/register?authentication=<authenticationToken>
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
    post '/v1/appointment/register?' do

        # Validate the input parameters
        request_body = get_request_JSON

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ## muck with the request based on what internal needs
        business_entity = get_business_entity(pass_in_token)
        #business_entity = 1
        
        ## add business entity to the request
        request_body['business_entity_id'] = business_entity
        request_body['notification_type'] = 2

        ## register callback url
        LOG.debug(request_body)

        ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
        urlapptreg = ''
        urlapptreg << API_SVC_URL
        urlapptreg << 'notification_callbacks.json?token='
        urlapptreg << URI::encode(pass_in_token)

        LOG.debug("url for appointment register: " + urlapptreg)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlapptreg, "", request_body.to_json, "POST")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        body(resp.body)

        status response_code

    end

    #  update register for appointment notifications
    #
    # PUT /v1/appointment/register?authentication=<authenticationToken>
    #
    # Params definition
    # :id - the register callback id
    # :notification_active  - flag to indicate if the callback should be made
    # :notification_callback_url - URL address to make the callback to when appointment changes
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
    put '/v1/appointment/register?' do

        # Validate the input parameters
        request_body = get_request_JSON

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ## muck with the request based on what internal needs
        business_entity = get_business_entity(pass_in_token)
        #business_entity = 1
        
        callbackid = request_body['id']

        ## add business entity to the request
        request_body['business_entity_id'] = business_entity
        request_body['notification_type'] = 2

        ## register callback url
        LOG.debug(request_body)

        ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
        urlapptreg = ''
        urlapptreg << API_SVC_URL
        urlapptreg << 'notification_callbacks/'
        urlapptreg << callbackid
        urlapptreg << '.json?token='
        urlapptreg << URI::encode(pass_in_token)

        LOG.debug("url for appointment register: " + urlapptreg)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlapptreg, "", request_body.to_json, "PUT")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        body(resp.body)

        status response_code

    end

    #  delete register for appointment notifications
    #
    # DELETE /v1/appointment/register?authentication=<authenticationToken>
    #
    # Params definition
    # :id - the register callback id
    # :notification_active  - flag to indicate if the callback should be made
    # :notification_callback_url - URL address to make the callback to when appointment changes
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
    delete '/v1/appointment/register?' do

        # Validate the input parameters
        request_body = get_request_JSON

        ## token management. Need unencoded tokens!
        pass_in_token = URI::decode(params[:authentication])

        ## muck with the request based on what internal needs
        business_entity = get_business_entity(pass_in_token)
        #business_entity = 1
        
        callbackid = request_body['id']

        ## add business entity to the request
        request_body['business_entity_id'] = business_entity
        request_body['notification_type'] = 2

        ## register callback url
        LOG.debug(request_body)

        ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
        urlapptreg = ''
        urlapptreg << API_SVC_URL
        urlapptreg << 'notification_callbacks/'
        urlapptreg << callbackid
        urlapptreg << '.json?token='
        urlapptreg << URI::encode(pass_in_token)

        LOG.debug("url for appointment register: " + urlapptreg)
        #LOG.debug(request_body.to_json)
        
        resp = generate_http_request(urlapptreg, "", request_body.to_json, "DELETE")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        body(resp.body)

        status response_code

    end

end