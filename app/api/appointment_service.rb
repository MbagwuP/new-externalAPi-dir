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
  # {
  #     "appointment": {
  #     "appointment_status_id": "1",
  #     "end_time": "2014-01-17 10:00:00 -05:00",
  #     "location_id": "3695",
  #     "nature_of_visit_id": "25470",
  #     "patients": [
  #     {
  #         "id": "d380643f-bbd1-4ee1-a3fe-9728e654aeee",
  #     "comments": ""
  # }
  # ],
  #     "provider_id": "3538",
  #     "resource_id": "8088",
  #     "start_time": "2014-01-17 09:00:00 -05:00"
  # }
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
    pass_in_token = CGI::unescape(params[:authentication])

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
    request_body['appointment']['reason_for_visit'] = request_body['appointment'].delete('chief_complaint')

    ## validate the provider
    providerids = get_providers_by_business_entity(business_entity, pass_in_token)

    ## validate the request based on token
    check_for_valid_provider(providerids, providerid)

    ## retrieve the internal patient id for the request
    patientid = ''
    request_body['appointment']['patients'].each { |x|

      patientid = x['id'].to_s

      #LOG.debug(patientid)

      patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)

      x['id'] = patientid

      #LOG.debug(patientid)
    }

    #LOG.debug(request_body)

    ## http://localservices.carecloud.local:3000/providers/2/appointments.json?token=
    urlapptcrt = ''
    urlapptcrt << API_SVC_URL
    urlapptcrt << 'providers/'
    urlapptcrt << providerid.to_s
    urlapptcrt << '/appointments.json?token='
    urlapptcrt << CGI::escape(pass_in_token)

    begin
      p  urlapptcrt
      response = RestClient.post(urlapptcrt, request_body.to_json, :content_type => :json)
    rescue => e
      #binding.pry 
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse(response.body)
    the_response_hash = {:appointment => parsed['appointment']['external_id'].to_s}
    body(the_response_hash.to_json)
    status HTTP_CREATED

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
  #     urlapptupd << CGI::escape(params[:authentication])
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
    pass_in_token = CGI::unescape(params[:authentication])

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
    urlapptdel << CGI::escape(pass_in_token)
    urlapptdel << '&business_entity_id='
    urlapptdel << business_entity

    begin
      response = RestClient.delete(urlapptdel)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Deletion Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Deletion Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = response.body
    body(parsed)

    status HTTP_OK

  end

  # Endpoint to change appointment status to checked-in
  # Parameters
  # :id => Appointment ID
  #http://localservices.carecloud.local:8888/v1/appointment/032ea3e9-fc99-4c1c-8d85-99b4142aec9c/checkin?authentication=AQIC5wM2LY4Sfcwvx_K-0r2wtxhPOGliZDxq6y11p1osMoI.*AAJTSQACMDE.*
  put '/v1/appointment/:id/checkin?' do
    request_body = get_request_JSON
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    appointmentid = get_appointment_internal_id(params[:id], business_entity, pass_in_token)

    # 'appointments/:business_entity_id/:id/cancel_appointment.:format' => "appointments#cancel"
    urlapptcheckin = "#{API_SVC_URL}appointments/#{business_entity}/#{appointmentid}/checkin.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.put(urlapptcheckin, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Check In has Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Check In has Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    body('{"Update":"Patient has been checked in"}')
    status HTTP_OK

  end


  # Endpoint to cancel Appointments
  # Parameters
  # :id => Appointment ID
  # request => {"cancellation_comments":""}

  post '/v1/appointment/:id/cancel_appointment?' do
    request_body = get_request_JSON
    request_body['appointment_cancellation_reason_id'] = 4
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    ## request parameter validation
    business_entity = get_business_entity(pass_in_token)
    appointmentid = get_appointment_internal_id(params[:id], business_entity, pass_in_token)

    # 'appointments/:business_entity_id/:id/cancel_appointment.:format' => "appointments#cancel"
    urlapptcancel = "#{API_SVC_URL}appointments/#{business_entity}/#{appointmentid}/cancel_appointment.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.post(urlapptcancel, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Candelation has Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Cancelation has Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    filtered_data = {}
    filtered_data["id"] = parsed["external_id"]
    filtered_data["start_time"] = parsed["start_time"]
    filtered_data["cancellation_comments"] = parsed["cancellation_comments"]
    filtered_data["updated_at"] = parsed["updated_at"]


    body(filtered_data.to_json)

    status HTTP_OK

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
  #http://localservices.carecloud.local:9292/v1/appointment/listbyid/4662bed6-ada6-419e-b5a0-7201b62c497b?authentication=AQIC5wM2LY4SfczXn0xHVNrI7IfTlq8lm1vjhpv%2FVmYVJ5k%3D%40AAJTSQACMDMAAlNLAAotOTQ3NDE4MjA2AAJTMQACMDE%3D%23
  get '/v1/appointment/listbydate/:date/:providerid?' do

    # Validate the input parameters
    validate_param(params[:providerid], PROVIDER_REGEX, PROVIDER_MAX_LEN)
    providerid = params[:providerid]

    validate_param(params[:date], DATE_REGEX, DATE_MAX_LEN)
    the_date = params[:date]

    #format to what the devservice needs
    providerid.slice!(/^provider-/)

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

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
    urlappt << CGI::escape(pass_in_token)
    urlappt << '&date='
    urlappt << the_date


    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    # iterate the array of appointments
    parsed["appointments"].each { |x|
      x['id'] = x['external_id']
      x['patient']['id'] = x['patient']['external_id']
      x['chief_complaint'] = x.delete('reason_for_visit')
    }

    #LOG.debug(parsed)
    body(parsed.to_json)

    status HTTP_OK

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
    pass_in_token = CGI::unescape(params[:authentication])

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
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)
    appt = parsed[0]
    appt['id'] = appt['external_id']
    appt['appointment']['chief_complaint'] = appt['appointment'].delete('reason_for_visit')
    body(parsed.to_json)
    status HTTP_OK

  end

  ##  get appointments by id
  #
  # GET /v2/appointment/listbyid/<appointmentid#>?authentication=<authenticationToken>
  #
  # Params definition
  # :appointmentid - the appointment identification number
  #    (ex: abcd1234)
  #
  # server action: Return appointment information for id
  # server response:
  # --> if data found: 200, with array of appointment data in response body
  # --> if not authorized: 401
  # --> if appointment id not found: 404
  # --> if exception: 500
  get '/v2/appointment/listbyid/:appointmentid?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

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
    urlappt << '/listbyexternalid2.json?token='
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt, :api_key => APP_API_KEY)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)

    pid = []
    # iterate the array of appointments
    # iterate the array of appointments
    # iterate the array of appointments
    parsed.each { |x|
      x[1]['appointment_id'] = x[1]['appointment_external_id']
      pid = x[1]['patient_ext_id']
    }

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity
    urlpatient << '/patients/'
    urlpatient << pid
    urlpatient << '/externalid.json?token='
    urlpatient << CGI::escape(pass_in_token)
    urlpatient << '&do_full_export=true'

    begin
      response = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Patient Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed2 = JSON.parse(response.body)

    result = []
    result << parsed
    result << parsed2
    #LOG.debug "BODY RETURNED "
    #LOG.debug(result.to_json)
    body(result.to_json)

    status HTTP_OK
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
    pass_in_token = CGI::unescape(params[:authentication])

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
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)
    parsed.each { |x|
      x['appointment']['id'] = x['appointment']['external_id']
    }

    body(parsed.to_json)

    status HTTP_OK

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
    pass_in_token = CGI::unescape(params[:authentication])

    ##  get providers by business entity - check to make sure they are legit in pass in
    business_entity = get_business_entity(pass_in_token)

    patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)

    #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424
    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt << patientid
    urlappt << '/listbypatient.json?token='
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    parsed.each { |x|
      x['id'] = x['external_id']
    }

    body(parsed.to_json)

    status HTTP_OK

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
    pass_in_token = CGI::unescape(params[:authentication])

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
    urlappt << CGI::escape(pass_in_token)


    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)
    parsed.each { |x|
      x['appointment']['id'] = x['appointment']['external_id']
    }

    body(parsed.to_json)

    status HTTP_OK

  end

  ##  get appointments by resource id
  # Test - URL :: /v1/appointments/listbyresource/7/date/20140421?authentication=
  #
  # GET /v1/appointments/listbyresource/<resource>?authentication=<authenticationToken>
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
  get '/v1/appointments/listbyresource/:resourceid/date/:date?' do

    # Validate the input parameters
    resourceid = params[:resourceid]

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    ##  get providers by business entity - check to make sure they are legit in pass in
    business_entity = get_business_entity(pass_in_token)

    #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424
    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt << resourceid
    urlappt << '/'
    urlappt << params[:date]
    urlappt << '/listbyresourceanddate.json?token='
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    parsed.each { |x|
      x['appointment']['id'] = x['appointment']['external_id']
      x['appointment']['chief_complaint'] = x['appointment'].delete('reason_for_visit')
    }

    body(parsed.to_json)

    status HTTP_OK

  end

  ##  get appointments_blockouts by resource id
  # Test - URL :: /v1/appointmentblockouts/listbyresourceanddate/7/date/20140421?authentication=TOKEN&include_appointments=true
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
  get '/v1/appointmentblockouts/listbyresourceanddate/:resourceid/date/:date?' do
    # Validate the input parameters
    resourceid = params[:resourceid]
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    ##  get providers by business entity - check to make sure they are legit in pass in
    business_entity = get_business_entity(pass_in_token)

    #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt << resourceid
    urlappt << '/'
    urlappt << params[:date]
    urlappt << '/list_by_resource.json?token='
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    data = Array.new
    parsed = Hash.new
    parsed['block_outs'] = JSON.parse(response.body)
    data << parsed
    if params[:include_appointments] == true or params[:include_appointments] == 'true'

      urlappt = ''
      urlappt << API_SVC_URL
      urlappt << 'appointments/'
      urlappt << business_entity
      urlappt << '/'
      urlappt << resourceid
      urlappt << '/'
      urlappt << params[:date]
      urlappt << '/listbyresourceanddate.json?token='
      urlappt << CGI::escape(pass_in_token)

      begin
        response = RestClient.get(urlappt)
      rescue => e
        begin
          errmsg = "Appointment Look Up Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      parsed2 = JSON.parse(response.body)
      parsed2.each { |x|
        x['appointment']['id'] = x['appointment']['external_id']
      }
      data << parsed2
    end

    body(data.to_json)
    status HTTP_OK

  end

  ##  get appointments_blockouts by location id
  # Test - URL :: /v1/appointmentblockouts/listbylocationanddate/33/date/20100906?authentication=
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
  get '/v1/appointmentblockouts/listbylocationanddate/:locationid/date/:date?' do
    # Validate the input parameters
    locationid = params[:locationid]
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    ##  get providers by business entity - check to make sure they are legit in pass in
    business_entity = get_business_entity(pass_in_token)

    #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt << locationid
    urlappt << '/'
    urlappt << params[:date]
    urlappt << '/list_by_location.json?token='
    urlappt << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    body(parsed.to_json)
    status HTTP_OK

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
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    #http://localservices.carecloud.local:3000/public/businesses/1/locations.json?token=
    urllocation = ''
    urllocation << API_SVC_URL
    urllocation << 'public/businesses/'
    urllocation << business_entity
    urllocation << '/locations.json?token='
    urllocation << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urllocation)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK
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
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    #http://localservices.carecloud.local:3000/appointments/1/statuses.json?token=
    urllocation = ''
    urllocation << API_SVC_URL
    urllocation << 'appointments/'
    urllocation << business_entity
    urllocation << '/statuses.json?token='
    urllocation << CGI::escape(pass_in_token)


    resp = get(urllocation)
    body(resp.body)
    status HTTP_OK

  end




  #  get All location information
  # Ellkay needed all locations id for mapping orginial v1 location endpoint did not return all locations
  #
  # server action: Return location information for authenticated user
  # server response:
  # --> if data found: 200, with location data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/appointment/all_locations?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    #http://localservices.carecloud.local:3000/public/businesses/1/locations.json?token=
    urllocation = ''
    urllocation << API_SVC_URL
    urllocation << 'businesses/'
    urllocation << business_entity
    urllocation << '/location.json?token='
    urllocation << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urllocation)
    rescue => e
      begin
        errmsg = "Appointment Locations Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)
    filtered_data = []
    parsed.each do |data|
      temp = {}
      temp['id'] = data['id']
      temp['location_name'] = data['name']
      filtered_data << temp
    end

    body(filtered_data.to_json)
    status HTTP_OK
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
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)


    #http://localservices.carecloud.local:3000/appointments/1/resources.json?token=
    urlresource = ''
    urlresource << API_SVC_URL
    urlresource << 'appointments/'
    urlresource << business_entity
    urlresource << '/resources.json?token='
    urlresource << CGI::escape(pass_in_token)

    resp = get(urlresource)
    body(resp.body)
    status HTTP_OK

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
    pass_in_token = CGI::unescape(params[:authentication])

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)
    #business_entity = 1

    ## add business entity to the request
    request_body['business_entity_id'] = business_entity
    request_body['notification_type'] = 2

    ## register callback url
    #LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlapptreg = ''
    urlapptreg << API_SVC_URL
    urlapptreg << 'notification_callbacks.json?token='
    urlapptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.post(urlapptreg, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)
    body(parsed.to_json)
    status HTTP_CREATED

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
    pass_in_token = CGI::unescape(params[:authentication])

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)
    #business_entity = 1

    callbackid = request_body['id']

    ## add business entity to the request
    request_body['business_entity_id'] = business_entity
    request_body['notification_type'] = 2

    ## register callback url
    #LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlapptreg = ''
    urlapptreg << API_SVC_URL
    urlapptreg << 'notification_callbacks/'
    urlapptreg << callbackid
    urlapptreg << '.json?token='
    urlapptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.put(urlapptreg, request_body.to_json, :content_type => :json)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK

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
    pass_in_token = CGI::unescape(params[:authentication])

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)
    #business_entity = 1

    callbackid = request_body['id']

    ## add business entity to the request
    request_body['business_entity_id'] = business_entity
    request_body['notification_type'] = 2

    ## register callback url
    #LOG.debug(request_body)

    ##http://localservices.carecloud.local:3000/notification_callbacks.json?token=
    urlapptreg = ''
    urlapptreg << API_SVC_URL
    urlapptreg << 'notification_callbacks/'
    urlapptreg << callbackid
    urlapptreg << '.json?token='
    urlapptreg << CGI::escape(pass_in_token)

    begin
      response = RestClient.delete(urlapptreg)
    rescue => e
      begin
        errmsg = "Appointment Deletion Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK

  end


  ##  sets patient_contacted to true or false
  #
  # POST v1/appointment/patientcontacted/:appointmentid?authentication=<authenticationToken>
  #
  # Params definition
  # :status - true or false
  #    {
  #    "status":"t"
  #    }
  #
  # server action: Return appointment information for selected provider
  # server response:
  # --> if data found: 200, with array of appointment data in response body
  # --> if not authorized: 401
  # --> if provider not found: 404
  # --> if exception: 500
  post '/v1/appointment/patientcontacted/:appointmentid?' do
    request_body = get_request_JSON
    appt_id = params[:appointmentid]
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt << appt_id
    urlappt << '/patient_contacted.json?token='
    urlappt << CGI::escape(pass_in_token)

    LOG.debug("URL:" + urlappt)

    begin
      response = RestClient.post(urlappt, request_body.to_json, :content_type => :json )
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse(response.body)
    results = ("Patient Contacted has been set to '#{parsed['appointment']['patient_contacted']}' for Appointment: #{parsed['appointment']['external_id']}  ")
    body(results)
    status HTTP_OK
  end

  ##  Confirms Appointment Confirmation
  #
  # POST v1/appointment/patientconfirmed/:appointmentid?authentication=<authenticationToken>
  #
  # Params definition
  # {
  #     "date_confirmed": "",
  #     "communication_method_id": "",
  #     "communication_outcome_id": "",
  #     "comments": ""
  # }
  #
  # server action: Return appointment information for selected provider
  # server response:
  # --> if data found: 200, with array of appointment data in response body
  # --> if not authorized: 401
  # --> if provider not found: 404
  # --> if exception: 500
  post '/v1/appointment/patientconfirmed/:appointmentid?' do
    request_body = get_request_JSON
    appt_id = params[:appointmentid]
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt << appt_id
    urlappt << '/patient_confirmed.json?token='
    urlappt << CGI::escape(pass_in_token)

    LOG.debug("URL:" + urlappt)

    begin
      response = RestClient.post(urlappt, request_body.to_json, :content_type => :json )
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse(response.body)
    LOG.debug(parsed.inspect)
    results = ("Patient Confirmation has been updated for Appointment: #{params['appointmentid']}")
    body(results)
    status HTTP_OK
  end




  ##  gets the blockouts and appointments by business entity
  #
  # get /v1/schedule/:date/:appointment_status_id/:location_id/:resource_id?s?authentication=<authenticationToken>
  #
  # Params definition
  # :status - true or false
  # server action: Return appointment/blockout information for selected provider
  # server response:
  # --> if data found: 200, with array of appointment data in response body
  # --> if not authorized: 401
  # --> if provider not found: 404
  # --> if exception: 500

  #date - 2014-03-29
  #appointment_status - 1
  #location_id - location of appointment
  #resource_id - resource

  get '/v1/schedule/:date/getblockouts/:location_id/:resource_id?' do

    appt_id = params[:appointmentid]
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << business_entity
    urlappt << '/'
    urlappt <<  params[:date]
    urlappt << '/1/'
    urlappt <<  params[:location_id]
    urlappt << '/'
    urlappt <<  params[:resource_id]
    urlappt << '/getByDay.json?token='
    urlappt << CGI::escape(pass_in_token)

    LOG.debug("URL:" + urlappt)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    blockouts = parsed["theBlockouts"]
    blockouts.each do |bo|
      bo["appointment_blockout"].delete("end_hour_bak")
      bo["appointment_blockout"].delete("end_minutes")
      bo["appointment_blockout"].delete("start_minutes")
      bo["appointment_blockout"].delete("start_hour_bak")
    end
    body(blockouts.to_json)
    status HTTP_OK

  end


  #params none, just need to pass in a valid token
  # GET /v1/notificationcallbacks?authentication=<TOKEN>
  #get notification callback ids
  get '/v1/notificationcallbacks?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'notification_callbacks/'
    urlappt << business_entity
    urlappt << '/list_by_business_entity.json?token='
    urlappt << CGI::escape(pass_in_token)

    LOG.debug("URL:" + urlappt)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Notification Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response)
    status HTTP_OK
  end


  # Endpoint Created to return Appointment Templates Per BE
  # Parameters
  #    None:
  # https://api.carecloud.com/v1/appointment_templates?

  #get notification callback ids
  get '/v1/appointment_templates?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointment_templates/'
    urlappt << business_entity
    urlappt << '.json?token='
    urlappt << CGI::escape(pass_in_token)

    LOG.debug("URL:" + urlappt)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Template Look Up Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Template Look Up Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response)
    status HTTP_OK
  end


  # Endpoint Created to return Appointment Templates by Date Per BE
  # Parameters
  #    None:
  # https://api.carecloud.com/v1/appointment_templates?

  #get notification callback ids
  get '/v1/appointment_templates_by_dates/:date?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointment_templates/'
    urlappt << business_entity
    urlappt << '/date/'
    urlappt << params[:date]
    urlappt << '.json?token='
    urlappt << CGI::escape(pass_in_token)

    LOG.debug("URL:" + urlappt)

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Template Look Up Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Template Look Up Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response)
    status HTTP_OK
  end


  # Endpoint Created to return Appointment Templates by Location Per BE
  # Parameters
  #    None:
  # https://api.carecloud.com/v1/appointment_templates?

  #get notification callback ids
  get '/v1/appointment_templates/find_by_location/:location_id?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urllocation = "#{API_SVC_URL}appointment_templates/find_by_location/#{params[:location_id]}/#{business_entity}.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.get(urllocation)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Template Look Up Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Template Look Up Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response)
    status HTTP_OK
  end


  # Endpoint Created to return Appointment Templates by Resource Per BE
  # Parameters
  #    None:
  # https://api.carecloud.com/v1/appointment_templates?

  #get notification callback ids
  get '/v1/appointment_templates/find_by_resource/:resource_id?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlresource = "#{API_SVC_URL}appointment_templates/find_by_resource/#{params[:resource_id]}/#{business_entity}.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.get(urlresource)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Template Look Up Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Template Look Up Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response)
    status HTTP_OK
  end

  # Endpoint Created to return nature of visits tied to an Appointment Templates Id
  # Parameters
  #    None:
  # https://api.carecloud.com/v1/appointment_templates?
  # /v1/appointment_templates/find_nature_of_visit/37566?

  #get notification callback ids
  get '/v1/appointment_templates/find_nature_of_visit/:appointment_template_id?' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    urlresource = "#{API_SVC_URL}appointment_templates/find_nature_of_visit/#{params[:appointment_template_id]}/#{business_entity}.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.get(urlresource)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Template Look Up Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Appointment Template Look Up Failed - #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response)
    status HTTP_OK
  end



end