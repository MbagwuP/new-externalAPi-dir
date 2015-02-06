class ApiService < Sinatra::Base

  get '/v2/appointment/listbydate/:date/:providerid?' do
    # Validate the input parameters
    validate_param(params[:providerid], PROVIDER_REGEX, PROVIDER_MAX_LEN)
    providerid = params[:providerid]

    validate_param(params[:date], DATE_REGEX, DATE_MAX_LEN)
    the_date = params[:date]

    #format to what the devservice needs
    providerid.slice!(/^provider-/)

    providerids = get_providers_by_business_entity(current_business_entity, oauth_token)

    ## validate the request based on token
    check_for_valid_provider(providerids, providerid)

    urlappt = webservices_uri "providers/#{providerid}/appointments.json",
                              {token: escaped_oauth_token, date: the_date, business_entity_id: current_business_entity, local_timezone: (local_timezone? ? 'true' : nil)}.compact

    response = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    parsed = JSON.parse(response.body)

    # iterate the array of appointments
    parsed["appointments"].each { |x|
      x['id'] = x['external_id']
      x['patient']['id'] = x['patient']['external_id']
    }

    #LOG.debug(parsed)
    body(parsed.to_json)
    status HTTP_OK
  end


  get '/v2/appointmentblockouts/listbyresourceanddate/:resourceid/date/:date?' do
    resourceid = params[:resourceid]

    urlappt = webservices_uri "appointments/#{current_business_entity}/#{resourceid}/#{params[:date]}/list_by_resource.json", token: escaped_oauth_token

    response = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt)
    end

    data = {}
    data['block_outs'] = JSON.parse(response.body)

    if params[:include_appointments] == true or params[:include_appointments] == 'true'
      urlappt = webservices_uri "appointments/#{current_business_entity}/#{resourceid}/#{params[:date]}/listbyresourceanddate.json", token: escaped_oauth_token
      response = rescue_service_call 'Appointment Look Up' do
        RestClient.get(urlappt)
      end

      appointments_data = JSON.parse(response.body)
      appointments_data.each { |x| x['appointment']['id'] = x['appointment']['external_id'] }
      data['appointments'] = appointments_data
    end

    body(data.to_json)
    status HTTP_OK
  end


  get '/v2/appointment/listbyresource/:resource_id' do
    resource_id = params[:resource_id]
    #LOG.debug(business_entity)
    #
    #http://devservices.carecloud.local/appointments/1/2/listbypatient.json?token=&date=20130424
    urlappt = webservices_uri "appointments/#{current_business_entity}/#{resource_id}/listbyresource.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.compact

    response = rescue_service_call 'Appointment Look Up' do
      RestClient.post(urlappt, nil, :api_key => APP_API_KEY)
    end

    parsed = JSON.parse(response.body)
    parsed.each { |x|
      x['appointment']['id'] = x['appointment']['external_id']
    }

    body(parsed.to_json)
    status HTTP_OK
  end


  get '/v2/appointment/statuses' do
    #http://localservices.carecloud.local:3000/appointments/1/statuses.json?token=
    urllocation = webservices_uri "appointments/#{current_business_entity}/statuses.json", token: escaped_oauth_token

    resp = rescue_service_call 'Appointment Status Look Up' do
      RestClient.get(urllocation, :api_key => APP_API_KEY)
    end

    body(resp.body)
    status HTTP_OK
  end


  get '/v2/schedule/:date/getblockouts/:location_id/:resource_id' do
    urlappt = webservices_uri "appointments/#{current_business_entity}/#{params[:date]}/1/#{params[:location_id]}/#{params[:resource_id]}/getByDay.json",
              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.compact

    response = rescue_service_call 'Appointment Look Up' do
      response = RestClient.get(urlappt)
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


  get '/v2/appointment_templates' do

    urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.compact
    LOG.debug("URL:" + urlappt)

    response = rescue_service_call 'Appointment Template Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    body(response)
    status HTTP_OK
  end


  get '/v2/resources/:resource_id/appointment_templates' do
    # /v2/resources/8088/appointment_templates?location_id=299&nature_of_visit_id=1414&start_date=2015-01-01&end_date=2015-01-30
    if params[:location_id]
      nil
    end
  end


  # /v2/appointments
  # /v2/appointment/create (legacy)
  post /\/v2\/(appointment\/create|appointments)/ do
    # Validate the input parameters
    request_body = get_request_JSON

    begin
      providerid = request_body['appointment']['provider_id']
      request_body['appointment'].delete('provider_id')
    rescue
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Provider id must be passed in"}'
    end

    ## validate the provider
    providerids = get_providers_by_business_entity(current_business_entity, oauth_token)
    ## validate the request based on token
    check_for_valid_provider(providerids, providerid)

    #LOG.debug(request_body)

    ## http://localservices.carecloud.local:3000/providers/2/appointments.json?token=
    urlapptcrt = webservices_uri "providers/#{providerid}/appointments.json", token: escaped_oauth_token, business_entity_id: current_business_entity

    begin
      response = RestClient.post(urlapptcrt, request_body.to_json,
        {:content_type => :json, :api_key => APP_API_KEY})
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Creation Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse(response.body)
    the_response_hash = {:appointment => parsed['appointment']['external_id'].to_s}
    body(the_response_hash.to_json)
    status HTTP_CREATED
  end

end
