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
      x.rename_key 'nature_of_visit_name', 'visit_reason_name'
      x.rename_key 'nature_of_visit_flagged', 'visit_reason_flagged'
    }

    #LOG.debug(parsed)
    body(parsed.to_json)
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


  get /\/v2\/(appointment\/statuses|appointment_statuses)/ do
    #http://localservices.carecloud.local:3000/appointments/1/statuses.json?token=
    urllocation = webservices_uri "appointments/#{current_business_entity}/statuses.json", token: escaped_oauth_token

    resp = rescue_service_call 'Appointment Status Look Up' do
      RestClient.get(urllocation, :api_key => APP_API_KEY)
    end

    body(resp.body)
    status HTTP_OK
  end


  # /v2/appointments
  get '/v2/appointments' do
    forwarded_params = {resource_ids: params[:resource_id], location_ids: params[:location_id], from: params[:start_date], to: params[:end_date]}
    using_date_filter = params[:start_date] && params[:end_date]
    missing_one_date_filter_field = [params[:start_date], params[:end_date]].compact.length == 1
    forwarded_params[:from] = forwarded_params[:from] + ' 00:00:00' if using_date_filter
    forwarded_params[:to] = forwarded_params[:to] + ' 23:59:59' if using_date_filter
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Both start_date and end_date are required for date filtering."}' if missing_one_date_filter_field
    urlappt = webservices_uri "appointments/#{current_business_entity}/getByDateRange.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil), use_current_business_entity: 'true'}.merge(forwarded_params).compact

    resp = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    resp = JSON.parse(resp)['theAppointments']
    body resp.to_json
  end


  get '/v2/appointments/:appointment_id' do
    urlappt = webservices_uri "appointments/#{current_business_entity}/#{params[:appointment_id]}/find_by_external_id.json",
      token: escaped_oauth_token, include_confirmation_method: 'true'

    resp = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    body(resp)
    status HTTP_OK
  end


  post '/v2/appointments/:appointment_id/confirmation' do
    request_body = get_request_JSON
    communication_method_slug = request_body.delete('communication_method')
    communication_outcome_slug = request_body.delete('communication_outcome')

    request_body['communication_method_id'] = communication_methods[communication_method_slug]
    request_body['communication_outcome_id'] = communication_outcomes[communication_outcome_slug]
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication method."}' if request_body['communication_method_id'].nil?
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication outcome."}' if request_body['communication_outcome_id'].nil?

    urlconf = webservices_uri "appointments/#{current_business_entity}/#{request_body['appointment_id']}/patient_confirmed.json",
      token: escaped_oauth_token

    resp = rescue_service_call 'Confirmation Creation' do
      RestClient.post(urlconf, request_body, :api_key => APP_API_KEY)
    end

    body(resp)
  end


  # /v2/appointments
  # /v2/appointment/create (legacy)
  post /\/v2\/(appointment\/create|appointments)/ do
    # Validate the input parameters
    request_body = get_request_JSON
    providerid = request_body['appointment']['provider_id']

    begin
      request_body['appointment'].delete('provider_id')
      if request_body['appointment']['visit_reason_id']
        request_body['appointment']['nature_of_visit_id'] = request_body['appointment']['visit_reason_id']
        request_body['appointment'].delete('visit_reason_id')
      end
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
