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

        ## muck with the request based on what internal needs
        business_entity = get_business_entity(params[:authentication])
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
        providerids = get_providers_by_business_entity(business_entity, params[:authentication])

        begin
            invalid_provider = true
            providerids['providers'].each { |x| 
                
                if x['id'].to_s == providerid.to_s
                    invalid_provider = false
                    break
                end
            }

            if invalid_provider
                api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
            end

        rescue
            api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
        end

        ## retrieve the internal patient id for the request
        patientid = ''
        request_body['appointment']['patients'].each { |x| 

            patientid = x['id'].to_s
 
            LOG.debug(patientid)

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

                    patientid = parsed["patient"]["id"].to_s

                    LOG.debug(patientid)

                    x['id'] = patientid

                else
                    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Cannot locate patient record"}' 
                end

            end
        }

        LOG.debug(request_body)

        ## http://localservices.carecloud.local:3000/providers/2/appointments.json?token=
        urlapptcrt = ''
        urlapptcrt << API_SVC_URL
        urlapptcrt << 'providers/'
        urlapptcrt << providerid.to_s
        urlapptcrt << '/appointments.json?token='
        urlapptcrt << URI::encode(params[:authentication])

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

        ## request parameter validation
        business_entity = get_business_entity(params[:authentication])

        providerid = params[:providerid]

         ## validate the provider
        providerids = get_providers_by_business_entity(business_entity, params[:authentication])

        begin
            invalid_provider = true
            providerids['providers'].each { |x| 
                
                if x['id'].to_s == providerid.to_s
                    invalid_provider = false
                    break
                end
            }

            if invalid_provider
                api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
            end

        rescue
            api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
        end


        ## /providers/:provider_id/appointments/:id(.:format)  {:action=>"destroy", :controller=>"provider_appointments"}
        urlapptdel = ''
        urlapptdel << API_SVC_URL
        urlapptdel << 'providers/'
        urlapptdel << providerid
        urlapptdel << '/appointments/'
        urlapptdel << params[:appointmentid]
        urlapptdel << '.json?token='
        urlapptdel << URI::encode(params[:authentication])

        LOG.debug("url for appointment delete: " + urlapptdel)

        resp = generate_http_request(urlapptdel, "", "", "DELETE")

        response_code = map_response(resp.code)

        if response_code == HTTP_OK
                body(esp.body)
        else
            body(resp.body)
        end

        status response_code

    end


    ##  get appointments by provider id and date
    #
    # GET /v1/appointment/<date>/<providerid#>?authentication=<authenticationToken>
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
    get '/v1/appointment/:date/:providerid?' do

        # Validate the input parameters
        validate_param(params[:providerid], PROVIDER_REGEX, PROVIDER_MAX_LEN)
        providerid = params[:providerid]

        validate_param(params[:date], DATE_REGEX, DATE_MAX_LEN)
        the_date = params[:date]

        #format to what the devservice needs
        providerid.slice!(/^provider-/)

        ##  get providers by business entity - check to make sure they are legit in pass in
        business_entity = get_business_entity(params[:authentication])


        providerids = get_providers_by_business_entity(business_entity, params[:authentication])

        begin
            invalid_provider = true
            providerids['providers'].each { |x| 
                
                if x['id'].to_s == providerid.to_s
                    invalid_provider = false
                    break
                end
            }

            if invalid_provider
                api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
            end

        rescue
            api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid provider presented"}'
        end

        #http://devservices.carecloud.local/providers/2/appointments.json?token=&date=20130424
        urlappt = ''
        urlappt << API_SVC_URL
        urlappt << 'providers/'
        urlappt << providerid
        urlappt << '/appointments.json?token='
        urlappt << URI::encode(params[:authentication])
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
                    LOG.debug('here') 
                    LOG.debug(x['id'])
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

    

    #  get provider information
    #
    # GET /v1/appointment/providers?authentication=<authenticationToken>
    #
    # Params definition
    # :none  - will be based on authentication
    #
    # server action: Return provider information for authenticated user
    # server response:
    # --> if data found: 200, with provider data payload
    # --> if not authorized: 401
    # --> if not found: 404
    # --> if exception: 500
    get '/v1/appointment/providers?' do


        business_entity = get_business_entity(params[:authentication])
        LOG.debug(business_entity)

        ## save the result of this to the cache
        cache_key = "business-entity-" + business_entity + "-providers-" + URI::decode(params[:authentication])

        LOG.debug("cache key: " + cache_key)

        #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
        urlprovider = ''
        urlprovider << API_SVC_URL
        urlprovider << 'public/businesses/'
        urlprovider << business_entity
        urlprovider << '/providers.json?token='
        urlprovider << URI::encode(params[:authentication])

        LOG.debug("url for providers: " + urlprovider)

        resp = generate_http_request(urlprovider, "", "", "GET")

        LOG.debug(resp.body)

        ## cache the result
        begin
            settings.cache.set(cache_key, resp.body.to_s, 50000)
            LOG.debug("++++++++++cache set")
        rescue => e
            LOG.error("cannot reach cache store")
        end

        body(resp.body)

        status map_response(resp.code)

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


        business_entity = get_business_entity(params[:authentication])
        LOG.debug(business_entity)

        #http://localservices.carecloud.local:3000/public/businesses/1/locations.json?token=
        urllocation = ''
        urllocation << API_SVC_URL
        urllocation << 'public/businesses/'
        urllocation << business_entity
        urllocation << '/locations.json?token='
        urllocation << URI::encode(params[:authentication])

        LOG.debug("url for providers: " + urllocation)

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


        business_entity = get_business_entity(params[:authentication])
        LOG.debug(business_entity)

        #http://localservices.carecloud.local:3000/appointments/1/resources.json?token=
        urlresource = ''
        urlresource << API_SVC_URL
        urlresource << 'appointments/'
        urlresource << business_entity
        urlresource << '/resources.json?token='
        urlresource << URI::encode(params[:authentication])

        LOG.debug("url for resources: " + urlresource)

        resp = generate_http_request(urlresource, "", "", "GET")

        LOG.debug(resp.body)

        body(resp.body)

        status map_response(resp.code)

    end    

end