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
    blank_date_field_passed = (params.keys.include?('start_date') && params[:start_date].blank?) || (params.keys.include?('end_date') && params[:end_date].blank?)
    missing_one_date_filter_field = [params[:start_date], params[:end_date]].compact.length == 1
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Both start_date and end_date are required for date filtering."}' if missing_one_date_filter_field
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Date filtering fields cannot be blank."}' if blank_date_field_passed

    using_date_filter = params[:start_date] && params[:end_date]
    if !using_date_filter
      forwarded_params[:from] = Date.today.to_s
      forwarded_params[:to] = Date.today.to_s
    end
    forwarded_params[:from] = forwarded_params[:from] + ' 00:00:00'
    forwarded_params[:to] = forwarded_params[:to] + ' 23:59:59'

    urlappt = webservices_uri "appointments/#{current_business_entity}/getByDateRange.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil), use_current_business_entity: 'true'}.merge(forwarded_params).compact

    resp = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(resp)['theAppointments']
    jbuilder :list_appointments
  end


  get '/v2/appointments/:appointment_id' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' if !params[:appointment_id].is_guid?

    urlappt = webservices_uri "appointments/#{current_business_entity}/#{params[:appointment_id]}/find_by_external_id.json",
      token: escaped_oauth_token, include_confirmation_method: 'true'

    resp = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    filtered = JSON.parse(resp)['appointment']
    filtered.rename_key 'external_id', 'id'
    filtered.rename_key 'nature_of_visit_id', 'visit_reason_id'
    filtered.delete('created_by')
    filtered.delete('updated_by')
    filtered.delete('reason_for_visit')
    filtered['business_entity_id'] = current_business_entity

    if filtered['confirmation_method'] && filtered['confirmation_method']['communication_method']
      # build new confirmation_method hash, and replace the old one
      confirmation_method_id = filtered['confirmation_method']['communication_method']['id']
      confirmation_method = {
        id:   confirmation_method_id,
        slug: communication_methods.invert[confirmation_method_id]
      }
      filtered['preferred_confirmation_method'] = confirmation_method
      filtered.delete('confirmation_method')
    end

    body({appointment: filtered}.to_json)
    status HTTP_OK
  end


  post '/v2/appointments/:appointment_id/confirmation' do
    request_body = get_request_JSON
    communication_method_slug = request_body.delete('communication_method')
    communication_outcome_slug = request_body.delete('communication_outcome')

    request_body['appointment_id'] = params[:appointment_id]
    request_body['communication_method_id'] = communication_methods[communication_method_slug]
    request_body['communication_outcome_id'] = communication_outcomes[communication_outcome_slug]
    request_body.rename_key('communication_method_description', 'method_description') if request_body['communication_method_description'].present?
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication method."}' if request_body['communication_method_id'].nil?
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication outcome."}' if request_body['communication_outcome_id'].nil?

    urlconf = webservices_uri "appointments/#{current_business_entity}/#{request_body['appointment_id']}/patient_confirmed.json",
      token: escaped_oauth_token

    resp = rescue_service_call 'Confirmation Creation' do
      RestClient.post(urlconf, request_body, :api_key => APP_API_KEY)
    end

    filtered = JSON.parse(resp)
    filtered['appointment_confirmation']['appointment_id'] = params[:appointment_id]
    filtered['appointment_confirmation'].delete('is_automated')
    filtered['appointment_confirmation'].delete('redemption_code')
    filtered['appointment_confirmation'].delete('redemption_code_expiration')
    filtered['appointment_confirmation'].delete('created_by')
    filtered['appointment_confirmation'].delete('updated_by')
    communication_method_id = filtered['appointment_confirmation'].delete('communication_method_id')
    communication_outcome_id = filtered['appointment_confirmation'].delete('communication_outcome_id')
    filtered['appointment_confirmation'].rename_key('method_description', 'communication_method_description')
    filtered['appointment_confirmation']['communication_method'] = communication_methods.invert[communication_method_id]
    filtered['appointment_confirmation']['communication_outcome'] = communication_outcomes.invert[communication_outcome_id]

    body(filtered.to_json)
  end


  # /v2/appointments
  # /v2/appointment/create (legacy)
  post /\/v2\/(appointment\/create|appointments)\z/ do
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


  get '/v2/appointment_cancellation_reasons' do
    urlreasons = webservices_uri "appointment_cancellation_reasons/#{current_business_entity}/list_by_business_entity.json", token: escaped_oauth_token

    response = rescue_service_call 'Appointment Cancellation Reason' do
      RestClient.get(urlreasons, :api_key => APP_API_KEY)
    end

    parsed = JSON.parse(response)
    if [1, '1', true, 'true'].include? params[:global_only]
      parsed = parsed.map{|p| p if p['appointment_cancellation_reason']['business_entity_id'].nil? }.compact
    end
    parsed.each do |p|
      if p['appointment_cancellation_reason']['business_entity_id'].present?
        p['appointment_cancellation_reason']['business_entity_id'] = current_business_entity
      end
      p['appointment_cancellation_reason'].delete('created_by')
      p['appointment_cancellation_reason'].delete('updated_by')
    end

    body(parsed.to_json)
    status HTTP_OK
  end

  put '/v2/appointments/:id/cancel' do
    request_body = get_request_JSON
    urlapptcancel = webservices_uri "appointments/#{current_business_entity}/#{params[:id]}/cancel_appointment.json", token: escaped_oauth_token

    response = rescue_service_call 'Appointment Cancellation' do
      RestClient.post(urlapptcancel, request_body.to_json, :api_key => APP_API_KEY, :content_type => :json)
    end

    parsed = JSON.parse(response.body)
    filtered_data = {}
    filtered_data["appointment_id"] = parsed["external_id"]
    filtered_data["start_time"] = parsed["start_time"]
    filtered_data["appointment_cancellation_reason_id"] = parsed["appointment_cancellation_reason_id"]
    filtered_data["cancellation_details"] = parsed["cancellation_details"]
    filtered_data["cancellation_comments"] = parsed["cancellation_comments"]
    filtered_data["updated_at"] = parsed["updated_at"]

    body(filtered_data.to_json)

    status HTTP_OK
  end

end
