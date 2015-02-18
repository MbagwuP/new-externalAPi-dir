class ApiService < Sinatra::Base

  get '/v2/appointment_templates' do

    # urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
    # urlappt = webservices_uri "appointment_templates/list_by_business_entity_with_filtering",
    forwarded_params = {resource_id: params[:resource_id], location_id: params[:location_id], start_date: params[:start_date], end_date: params[:end_date]}
    using_date_filter = params[:start_date] && params[:end_date]
    missing_one_date_filter_field = [params[:start_date], params[:end_date]].compact.length == 1
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Both start_date and end_date are required for date filtering."}' if missing_one_date_filter_field

    urlappt = webservices_uri "appointment_templates/filtered/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact
    LOG.debug("URL:" + urlappt)

    response = rescue_service_call 'Appointment Template Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    response = JSON.parse(response)
    
    if using_date_filter
      response['appointment_templates'] = response['appointment_templates'].map do |template|
        x = template
        x[:occurences] = RecurringTimespan.new(template).occurences_in_date_range(params[:start_date], params[:end_date])
        x
      end
    end

    body(response.to_json)
    status HTTP_OK
  end


  get '/v2/resources/:resource_id/appointment_templates' do

    # urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
    # urlappt = webservices_uri "appointment_templates/list_by_business_entity_with_filtering",
    forwarded_params = {resource_id: params[:resource_id], location_id: params[:location_id], start_date: params[:start_date], end_date: params[:end_date]}
    using_date_filter = params[:start_date] && params[:end_date]
    missing_one_date_filter_field = [params[:start_date], params[:end_date]].compact.length == 1
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Both start_date and end_date are required for date filtering."}' if missing_one_date_filter_field

    urlappt = webservices_uri "appointment_templates/filtered/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact
    LOG.debug("URL:" + urlappt)

    response = rescue_service_call 'Appointment Template Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    response = JSON.parse(response)
    
    if using_date_filter
      response['appointment_templates'] = response['appointment_templates'].map do |template|
        x = template
        x[:occurences] = RecurringTimespan.new(template).occurences_in_date_range(params[:start_date], params[:end_date])
        x
      end
    end

    body(response.to_json)
    status HTTP_OK
  end

end
