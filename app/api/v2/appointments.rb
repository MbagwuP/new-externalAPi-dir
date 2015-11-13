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
      x.rename_key 'reason_for_visit', 'chief_complaint'
    }

    #LOG.debug(parsed)
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
    params[:use_pagination] = 'true' # comment this out as a backout strategy for pagination

    forwarded_params = {resource_ids: params[:resource_id], location_ids: params[:location_id], from: params[:start_date], to: params[:end_date],
                        page: params[:page], use_pagination: 'true'} # remove use_pagination here as a backout strategy for pagination

    params_error = ParamsValidator.new(params, :invalid_date_passed, :blank_date_field_passed, :missing_one_date_filter_field, :date_filter_range_too_long).error
    api_svc_halt HTTP_BAD_REQUEST, params_error if params_error.present?

    using_date_filter = params[:start_date] && params[:end_date]
    if !using_date_filter
      forwarded_params[:from] = Date.today.to_s
      forwarded_params[:to] = Date.today.to_s
    end
    forwarded_params[:from] = forwarded_params[:from] + ' 00:00:00'
    forwarded_params[:to] = forwarded_params[:to] + ' 23:59:59'

    urlappt = webservices_uri "appointments/#{current_business_entity}/getByDateRange.json",
                              {token: escaped_oauth_token, local_timezone: 'true', use_current_business_entity: 'true'}.merge(forwarded_params).compact

    resp = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    @resp = Oj.load(resp)['theAppointments']
    if [1,'1',true,'true'].include? params[:use_pagination] && !resp.headers[:link].nil?
      headers['Link'] = PaginationLinkBuilder.new(resp.headers[:link], ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['gateway_url'] + env['PATH_INFO'] + '?' + env['QUERY_STRING']).to_s
    end

    jbuilder :list_appointments
  end


  get '/v2/appointments/:appointment_id' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:appointment_id].is_guid?

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
    filtered.rename_key('reason_for_visit', 'chief_complaint')
    filtered['business_entity_id'] = current_business_entity

    if filtered['confirmation_method'] && filtered['confirmation_method']['communication_method']
      # build new confirmation_method hash, and replace the old one
      confirmation_method_id = filtered['confirmation_method']['communication_method']['id']
      confirmation_method = communication_methods.invert[confirmation_method_id]
      filtered['preferred_confirmation_method'] = confirmation_method
    else
      filtered['preferred_confirmation_method'] = nil
    end
    filtered.delete('confirmation_method')

    body({appointment: filtered}.to_json)
    status HTTP_OK
  end


  post '/v2/appointments/:appointment_id/confirmation' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:appointment_id].is_guid?

    request_body = get_request_JSON
    communication_method_slug = request_body.delete('communication_method')
    communication_outcome_slug = request_body.delete('communication_outcome')

    request_body['appointment_id'] = params[:appointment_id]
    request_body['communication_method_id'] = communication_methods[communication_method_slug]
    request_body['communication_outcome_id'] = communication_outcomes[communication_outcome_slug]
    request_body.rename_key('communication_method_description', 'method_description') if request_body['communication_method_description'].present?

    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication method."}' if request_body['communication_method_id'].nil? || communication_outcome_slug == 'none'
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication outcome."}' if request_body['communication_outcome_id'].nil?

    urlconf = webservices_uri "appointments/#{current_business_entity}/#{request_body['appointment_id']}/patient_confirmed.json",
      token: escaped_oauth_token

    resp = rescue_service_call 'Confirmation Creation' do
      RestClient.post(urlconf, request_body, :api_key => APP_API_KEY)
    end

    @confirmation = JSON.parse(resp)
    @appointment_id = params[:appointment_id]
    
    status HTTP_CREATED
    jbuilder :_appointment_confirmation
  end

  get '/v2/appointments/:appointment_id/confirmations' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:appointment_id].is_guid?

    urlappt = webservices_uri "appointments/#{current_business_entity}/#{params[:appointment_id]}/confirmations.json",
      token: escaped_oauth_token
    resp = rescue_service_call 'Appointment Confirmations' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end
    
    @resp = JSON.parse(resp)
    @appointment_id = params[:appointment_id]
    status HTTP_OK
    jbuilder :list_appointment_confirmations
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

    # accept "patient" or "patients", whose value can be either an object or an array containing one object
    request_body['appointment'].rename_key('patient', 'patients') if request_body['appointment'].keys.include?('patient')
    request_body['appointment']['patients'] = [request_body['appointment']['patients']] if request_body['appointment']['patients'].is_a?(Hash)
    request_body['appointment']['reason_for_visit'] = request_body['appointment'].delete('chief_complaint')

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
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:id].is_guid?

    request_body = get_request_JSON
    urlapptcancel = webservices_uri "appointments/#{current_business_entity}/#{params[:id]}/cancel_appointment.json", token: escaped_oauth_token

    response = rescue_service_call 'Appointment Cancellation', true do
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

  get '/v2/appointment_recalls' do
    forwarded_params = {from: params[:start_date], to: params[:end_date], use_pagination: 'true'}
    if forwarded_params[:from].blank? && forwarded_params[:to].blank?
      forwarded_params[:from] = Date.today.to_s
      forwarded_params[:to]   = Date.parse(7.days.since.to_s).to_s # default to the coming week's worth of recalls
    end
    params_error = ParamsValidator.new(forwarded_params, :invalid_date_passed, :blank_date_field_passed, :missing_one_date_filter_field, :date_filter_range_too_long).error
    api_svc_halt HTTP_BAD_REQUEST, params_error if params_error.present?

    urlrecalls = webservices_uri "businesses/#{current_business_entity}/recalls/list_by_business_entity_and_date_range.json", {token: escaped_oauth_token}.merge(forwarded_params)

    @resp = rescue_service_call 'Appointment Recall' do
      RestClient.get(urlrecalls, :api_key => APP_API_KEY)
    end
    if !@resp.headers[:link].nil?
      headers['Link'] = PaginationLinkBuilder.new(resp.headers[:link], ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['gateway_url'] + env['PATH_INFO'] + '?' + env['QUERY_STRING']).to_s
    end

    @resp = Oj.load(@resp)

    status HTTP_OK
    jbuilder :list_appointment_recalls
  end

  get '/v2/appointment_recall_types' do
    urlrecalltypes = webservices_uri "businesses/#{current_business_entity}/recall_types/list_by_business_entity.json", token: escaped_oauth_token

    @resp = rescue_service_call 'Appointment Recall Type' do
      RestClient.get(urlrecalltypes, :api_key => APP_API_KEY)
    end
    @resp = Oj.load(@resp)

    status HTTP_OK
    jbuilder :list_appointment_recall_types
  end

  put '/v2/appointment_recalls/:id' do
    urlrecall = webservices_uri "businesses/#{current_business_entity}/recalls/#{params[:id]}/update.json", token: escaped_oauth_token

    request_body = get_request_JSON
    update_json = {recall_status_id: recall_statuses[request_body['recall_status']]}

    @resp = rescue_service_call 'Appointment Recall' do
      RestClient.post(urlrecall, update_json, :api_key => APP_API_KEY)
    end

    status HTTP_NO_CONTENT
    nil
  end

end
