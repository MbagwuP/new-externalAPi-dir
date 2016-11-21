require 'json'
class ApiService < Sinatra::Base

  CREATE_PARAMS = %w(start_time end_time appointment_status_id location_id provider_id nature_of_visit_id reason_for_visit resource_id chief_complaint patients)

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
    forwarded_params = {resource_ids: params[:resource_id], location_ids: params[:location_id], page: params[:page], 
                        use_pagination: 'true', nature_of_visit_ids: params[:visit_reason_ids]}
    
    validate_date_filter_params! if date_filter_params?
    today = Date.today.to_s
    forwarded_params[:from] = (params.fetch('start_date',today) + ' 00:00:00')
    forwarded_params[:to]   = (params.fetch('end_date',today) + ' 23:59:59')
    urlappt = webservices_uri "appointments/#{current_business_entity}/getByDateRange.json",
                              {token: escaped_oauth_token, local_timezone: 'true', use_current_business_entity: 'true'}.merge(forwarded_params).compact

    resp = rescue_service_call 'Appointment Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end
    @resp = Oj.load(resp)['theAppointments']
    if !resp.headers[:link].nil?
      headers['Link'] = PaginationLinkBuilder.new(resp.headers[:link], ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['gateway_url'] + env['PATH_INFO'] + '?' + env['QUERY_STRING']).to_s
    end

    jbuilder :list_appointments
  end


  get '/v2/appointments/:appointment_id' do
    appointments = params[:appointment_id].split(',').map(&:strip)
    api_svc_halt HTTP_BAD_REQUEST, '{"error": "exeeded maximum number of appointments per call"}' if appointments.length > 25

    appointments.each do |appt|
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless appt.is_guid?
    end

    base_path = "appointments/#{current_business_entity}/#{params[:appointment_id]}/find_by_external_id.json"

    if (current_internal_request_header)
      url = webservices_uri base_path, include_confirmation_method: 'true'
      internal_signed_request = sign_internal_request(url: url, method: :get, headers: {accept: :json})
      resp = internal_signed_request.execute
    else
      url = webservices_uri base_path, token: escaped_oauth_token, include_confirmation_method: 'true'
      resp = rescue_service_call 'Appointment Look Up' do
        RestClient.get(url, :api_key => APP_API_KEY)
      end
    end

    @resp = JSON.parse(resp)

    if @resp.is_a?(Array)
      @resp.each do |appt|
        set_preferred_confirmation_method(appt['appointment'])
      end
      
      jbuilder :show_appointments
    else
      appt = @resp['appointment']
      set_preferred_confirmation_method(appt)
      @resp = {'appointment' => appt}

      jbuilder :show_appointment 
    end
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

    # support comments in the patient pbject for backwards compatibility
    # but give priority to comments in the appointment object to normalize
    # request with the appointment response payload
    request_body['appointment']['patients'][0]['comments'] = request_body['appointment']['comments'] if request_body['appointment'].has_key?('comments')

    # accept "patient" or "patients", whose value can be either an object or an array containing one object
    request_body['appointment'].rename_key('patient', 'patients') if request_body['appointment'].keys.include?('patient')
    request_body['appointment']['patients'] = [request_body['appointment']['patients']] if request_body['appointment']['patients'].is_a?(Hash)
    request_body['appointment']['reason_for_visit'] = request_body['appointment'].delete('chief_complaint')

    request_body['appointment'] = filter_request_body(request_body['appointment'], permit: CREATE_PARAMS)
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

  put '/v2/appointments/:id/check_in' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:id].is_guid?

    url_appt_check_in = webservices_uri "appointments/#{current_business_entity}/#{params[:id]}/checkin.json", token: escaped_oauth_token, v2: true

    response = rescue_service_call 'Appointment Check In', true do
      RestClient.put(url_appt_check_in, :api_key => APP_API_KEY, :content_type => :json)
    end

    @appt = JSON.parse(response)['appointment']
    set_preferred_confirmation_method(@appt)

    @resp = {'appointment' => @appt}
    jbuilder :show_appointment
  end

  put '/v2/appointments/:id/check_out' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:id].is_guid?

    url_appt_check_out = webservices_uri "appointments/#{current_business_entity}/#{params[:id]}/checkout.json", token: escaped_oauth_token, v2: true

    response = rescue_service_call 'Appointment Check In', true do
      RestClient.put(url_appt_check_out, :api_key => APP_API_KEY, :content_type => :json)
    end

    @appt = JSON.parse(response)['appointment']
    set_preferred_confirmation_method(@appt)

    @resp = {'appointment' => @appt}
    jbuilder :show_appointment
  end

  get '/v2/appointment_recalls' do
    forwarded_params = {start_date: params[:start_date], end_date: params[:end_date], use_pagination: 'true',page: params[:page]}
    if forwarded_params[:start_date].blank? && forwarded_params[:end_date].blank?
      forwarded_params[:start_date] = Date.today.to_s
      forwarded_params[:end_date]   = Date.parse(7.days.since.to_s).to_s # default to the coming week's worth of recalls
    elsif !forwarded_params[:start_date].blank? && forwarded_params[:end_date].blank?
      forwarded_params[:end_date]   = (Date.parse(forwarded_params[:start_date]) + 7.days).to_s # default to one week from the start date
    end
    
    params_error = ParamsValidator.new(forwarded_params, :invalid_date_passed, :blank_date_field_passed,
                                       :missing_one_date_filter_field, :date_filter_range_too_long, :end_date_is_before_start_date).error
    api_svc_halt HTTP_BAD_REQUEST, params_error if params_error.present?

    forwarded_params.rename_key(:start_date, :from) if forwarded_params[:start_date]
    forwarded_params.rename_key(:end_date, :to) if forwarded_params[:end_date]
    forwarded_params['recall_status_id'] = RecallStatus.parse_to_webservices(params['recall_status'])  if params['recall_status']

    urlrecalls = webservices_uri "businesses/#{current_business_entity}/recalls.json", {token: escaped_oauth_token}.merge(forwarded_params)

    @resp = rescue_service_call 'Appointment Recall' do
      RestClient.get(urlrecalls, :api_key => APP_API_KEY)
    end
    if !@resp.headers[:link].nil?
      headers['Link'] = PaginationLinkBuilder.new(@resp.headers[:link], ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['gateway_url'] + env['PATH_INFO'] + '?' + env['QUERY_STRING']).to_s
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

  get '/v2/appointment_recalls/:id' do
    urlrecall = webservices_uri "businesses/#{current_business_entity}/recalls/#{params[:id]}.json", token: escaped_oauth_token

    @resp = rescue_service_call 'Appointment Recall' do
      RestClient.get(urlrecall, :api_key => APP_API_KEY)
    end

    @resp = Oj.load(@resp)
    @resp['recall']['business_entity_id'] = current_business_entity
    status HTTP_OK
    jbuilder :show_appointment_recall
  end

  put '/v2/appointment_recalls/:id' do
    urlrecall = webservices_uri "businesses/#{current_business_entity}/recalls/#{params[:id]}/update.json", token: escaped_oauth_token

    request_body = get_request_JSON    
    update_json = {recall_status_id: RecallStatus.parse_to_webservices(request_body['recall_status']), comments: request_body['comments']}

    @resp = rescue_service_call 'Appointment Recall' do
      RestClient.post(urlrecall, update_json, :api_key => APP_API_KEY)
    end

    status HTTP_NO_CONTENT
    nil
  end

  get '/v2/waitlist' do

    api_svc_halt HTTP_BAD_REQUEST, '{"error": "Missing query parameters"}' unless params[:appointment_id]

    urlwaitlist_requests = webservices_uri "/scheduler/waitlist_requests.json", {token: escaped_oauth_token, id: params[:appointment_id], enforce_hold: true, from_appointment: true}

    begin
      @resp = rescue_service_call 'Waitlist' do
        RestClient.get(urlwaitlist_requests, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Waitlist Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    @resp = Oj.load(@resp)
    @resp.each { |waitlist_request| waitlist_request['business_entity_id'] = current_business_entity }

    status HTTP_OK
    jbuilder :list_waitlist_requests
  end

  post '/v2/waitlist/book' do
    request = get_request_JSON
    api_svc_halt HTTP_BAD_REQUEST, '{"error": "Missing query parameters"}' unless request['appointment_id']

    payload = {appointment_id: request['appointment_id'], waitlist_request_id: request['waitlist_request_id']}
    urlwaitlist_requests = webservices_uri "/scheduler/waitlist_requests/book.json", token: escaped_oauth_token

    begin
      @resp = rescue_service_call 'Book from waitlist' do
        RestClient.post(urlwaitlist_requests, payload,  :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Appointment Booking Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    @appt = JSON.parse(@resp)['appointment']
    set_preferred_confirmation_method(@appt)

    @resp = {'appointment' => @appt}
    status HTTP_OK
    jbuilder :show_appointment
  end
  
  get '/v2/appointment_availability' do
        
    begin
      request_body = AppointmentAvailability.new({'business_entity_id' => current_business_entity, 'token' => escaped_oauth_token}.merge(params).with_indifferent_access).structure_request_body
      appt_avail_url = webservices_uri "/appointment_availability.json", request_body
      @resp = rescue_service_call 'Appointment Availability Look Up' do
        { 'availabilities' => JSON.parse(RestClient.get(appt_avail_url)) }
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Appointment Availability Finder Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_BAD_REQUEST, errmsg
      end
    end
    
    @resp.to_json
    
    # jbuilder :appointment_availability
  end

end
