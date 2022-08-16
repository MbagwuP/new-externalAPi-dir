class ApiService < Sinatra::Base

  CREATE_PARAMS = %w(start_time end_time appointment_status_id location_id provider_id nature_of_visit_id reason_for_visit resource_id chief_complaint patients)
  APPOINTMENT_STATUS_CODES = %w(P I O C R)

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
                        use_pagination: 'true', nature_of_visit_ids: params[:visit_reason_ids], patient_ids: params[:patient_ids]}

    if params[:status].present?
      raise ArgumentError.new("Invalid appointment status") unless APPOINTMENT_STATUS_CODES.include?(params[:status].upcase)
      forwarded_params[:status_code] = params[:status]
    end

    if params['created_at_from'].present? || params['created_at_to'].present?
     params['created_at_to'] = params['created_at_from'] if params['created_at_from'].present? && params['created_at_to'].blank?
     params['created_at_from'] = params['created_at_to'] if params['created_at_to'].present? && params['created_at_from'].blank?
     created_at_params = true
    end

    if !created_at_params && params['start_date'].blank? && params['end_date'].blank? #no start, end or created_at params
      today = Date.today.to_s
      params['start_date'] =  today
      params['end_date'] = today
    else #no created at params
      validate_date_filter_params!
    end

    if params['created_at_from'].present? || params['created_at_to'].present?
     forwarded_params[:created_at_from] = params['created_at_from'] + ' 00:00:00'
     forwarded_params[:created_at_to]   = params['created_at_to'] + ' 23:59:59'
    end

    if params['start_date'].present? && params['end_date'].present?
      forwarded_params[:from] = params['start_date'] + ' 00:00:00'
      forwarded_params[:to]   = params['end_date'] + ' 23:59:59'
    end

    # webservices: AppointmentsController#get_appt_data_by_date_range
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


  # /v2/appointments/listbypatient?patient_id
  get '/v2/appointments/listbypatient' do
    patient_id = params[:patient_id]
    validate_patient_id_param(patient_id)

    base_path = "appointments/#{current_business_entity}/#{patient_id}/listbypatientid.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id },
      rescue_string: "Appointment by patient "
    )
    @resp = resp

    jbuilder :list_appointment_entries
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
      # NOTE: change the structure of some attributes if it's a internal request.
      @internal_request = true
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

  # will be depracated over time. POST appointments/:id/confirm will replace
  post '/v2/appointments/:appointment_id/confirmation' do
    appointment_guid_check(params[:appointment_id])

    request_body = get_request_JSON
    request_body['appointment_id'] = params[:appointment_id]
    transform_communication_params(request_body)

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

  post '/v2/appointments/:appointment_id/confirm' do
    appointment_guid_check(params[:appointment_id])

    request_body = get_request_JSON
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid Parameter- communication_outcome"}' if request_body.has_key?("communication_outcome")

    request_body['appointment_id'] = params[:appointment_id]
    transform_communication_params(request_body)

    urlconf = webservices_uri "appointments/#{current_business_entity}/#{request_body['appointment_id']}/patient_confirmed.json",
      token: escaped_oauth_token
    resp = rescue_service_call 'Confirmation Creation' do
      RestClient.post(urlconf, request_body, :api_key => APP_API_KEY)
    end

    @confirmation = JSON.parse(resp)
    @appointment_id = params[:appointment_id]

    status HTTP_CREATED
    jbuilder :_appointment_confirm
  end

  get '/v2/appointments/:appointment_id/confirmations' do
    appointment_guid_check(params[:appointment_id])

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

  # used to create an appointment communication (i.e reminder) but WILL NOT confirm an appointment. An appointment communication creates an appointment_confirmation instance.
  post '/v2/appointments/:appointment_id/communication' do
    appointment_guid_check(params[:appointment_id])

    request_body = get_request_JSON
    # If a communication_outcome value of CONFIRMED is passed in then an error is thrown to use the POST /confirm endpoint.  (POST /confirmation endpoint is being depracted)
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"This endpoint does not confirm an appointment. Use POST /confirm endpoint."}' if request_body["communication_outcome"] == "confirmed"

    request_body['appointment_id'] = params[:appointment_id]
    transform_communication_params(request_body)

    urlconf = webservices_uri "appointments/#{current_business_entity}/#{request_body['appointment_id']}/patient_confirmed.json",
      token: escaped_oauth_token

    resp = rescue_service_call 'Appointment Communication Creation' do
      RestClient.post(urlconf, request_body, :api_key => APP_API_KEY)
    end

    @apt_communication = JSON.parse(resp)
    @appointment_id = params[:appointment_id]

    status HTTP_CREATED
    jbuilder :_appointment_communication
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

    # accept "patient" or "patients", whose value can be either an object or an array containing one object (backwards compatibility support)
    request_body['appointment'].rename_key('patient', 'patients') if request_body['appointment'].keys.include?('patient')
    # normalize patient data into an Array to meet internal service's api contract
    request_body['appointment']['patients'] = Array.wrap(request_body['appointment']['patients']) # if request_body['appointment']['patients'].is_a?(Hash)
    # normalize comments on patient object.  This allows for comments to be specified on the patient object for backwards compatibility
    # but gives priority to comments in the appointment object
    request_body['appointment']['patients'].first['comments'] = request_body['appointment']['comments'] if request_body['appointment'].has_key?('comments')
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
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid communication method."}' if !visible_communication_method?(request_body['communication_method']) && !request_body['communication_method'].nil?

    communication_method_slug = request_body.delete('communication_method')
    request_body['communication_method_id'] = communication_methods[communication_method_slug]

    urlapptcancel = webservices_uri "appointments/#{current_business_entity}/#{params[:id]}/cancel_appointment.json", token: escaped_oauth_token

    response = rescue_service_call 'Appointment Cancellation', true do
      RestClient.post(urlapptcancel, request_body.to_json, :api_key => APP_API_KEY, :content_type => :json)
    end

    parsed = JSON.parse(response.body)
    filtered_data = {}
    filtered_data["appointment_id"] = parsed["appointment"]["external_id"]
    filtered_data["start_time"] = parsed["appointment"]["start_time"]
    filtered_data["appointment_cancellation_reason_id"] = parsed["appointment"]["appointment_cancellation_reason_id"]
    filtered_data["cancellation_details"] = parsed["appointment"]["cancellation_details"]
    filtered_data["cancellation_comments"] = parsed["appointment"]["cancellation_comments"]
    filtered_data["updated_at"] = parsed["appointment"]["updated_at"]
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

  put '/v2/appointments/:id/pending' do
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless params[:id].is_guid?

    url_appt_pending = webservices_uri "appointments/#{current_business_entity}/#{params[:id]}/pending.json", token: escaped_oauth_token, v2: true

    response = rescue_service_call 'Appointment Check In', true do
      RestClient.put(url_appt_pending, :api_key => APP_API_KEY, :content_type => :json)
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
    elsif forwarded_params[:start_date].blank? && !forwarded_params[:end_date].blank?
      api_svc_halt HTTP_BAD_REQUEST, "If you include the end_date parameter then a start_date parameter must be included."
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
      @resp = rescue_service_call 'Waitlist',true do
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
      if params["start_date"].blank? && params["end_date"].blank?
        today = Date.today.to_s
        params["start_date"] = today
        params["end_date"]   = today
      elsif !params["start_date"].blank? && params["end_date"].blank?
        params["end_date"]   = params["start_date"]
      end
      search_criteria = AppointmentAvailabilitySearchCriteria.new(params.merge('token' => escaped_oauth_token, 'business_entity_id' => current_business_entity)).query_params
      appt_avail_url = webservices_uri "/appointment_availability.json", search_criteria
      @resp = rescue_service_call 'Appointment Availability Look Up' do
        JSON.parse(RestClient.get(appt_avail_url))
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
  end

end
