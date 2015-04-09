class ApiService < Sinatra::Base

  get '/v2/appointment_templates' do

    # urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
    # urlappt = webservices_uri "appointment_templates/list_by_business_entity_with_filtering",
    forwarded_params = {resource_id: params[:resource_id], location_id: params[:location_id], start_date: params[:start_date], end_date: params[:end_date], include_expanded_info: 'true'}
    using_date_filter = params[:start_date] && params[:end_date]
    missing_one_date_filter_field = [params[:start_date], params[:end_date]].compact.length == 1
    blank_date_field_passed = (params.keys.include?('start_date') && params[:start_date].blank?) || (params.keys.include?('end_date') && params[:end_date].blank?)
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Date filtering fields cannot be blank."}' if blank_date_field_passed
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Both start_date and end_date are required for date filtering."}' if missing_one_date_filter_field

    urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact
    LOG.debug("URL:" + urlappt)

    response = rescue_service_call 'Appointment Template Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    response = JSON.parse(response)
    response = response.map { |x|
      if x['appointment_template']['status'] == 'A'
        x['appointment_template'].delete('status')
        x['appointment_template']['business_entity_id'] = current_business_entity
        x
      end
    }.compact

    if using_date_filter
      # fetch the BE's details, we need its local timezone
      urlbusentity = webservices_uri "businesses/#{current_business_entity}.json",
                                     {token: escaped_oauth_token, include_timezone: 'true', business_entity_id: current_business_entity}
      busentity = rescue_service_call 'Practice Look Up' do
        RestClient.get(urlbusentity)
      end
      busentity = JSON.parse(busentity)

      response = response.map { |template|
        template['appointment_template']['timezone_offset'] = busentity['business_entity']['timezone']['utc_delta']
        template['appointment_template']['timezone_name'] = busentity['business_entity']['timezone']['name']
        template['appointment_template'][:occurrences] = RecurringTimespan.new(template['appointment_template']).occurences_in_date_range(params[:start_date], params[:end_date])
        if template['appointment_template'][:occurrences].any?
          template
        else
          nil
        end
      }.compact
    end

    body(response.to_json)
    status HTTP_OK
  end


  get '/v2/appointment_resources/:resource_id/appointment_templates' do

    # urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
    # urlappt = webservices_uri "appointment_templates/list_by_business_entity_with_filtering",
    forwarded_params = {resource_id: params[:resource_id], location_id: params[:location_id], start_date: params[:start_date], end_date: params[:end_date], include_expanded_info: 'true'}
    using_date_filter = params[:start_date] && params[:end_date]
    missing_one_date_filter_field = [params[:start_date], params[:end_date]].compact.length == 1
    blank_date_field_passed = (params.keys.include?('start_date') && params[:start_date].blank?) || (params.keys.include?('end_date') && params[:end_date].blank?)
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Date filtering fields cannot be blank."}' if blank_date_field_passed
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Both start_date and end_date are required for date filtering."}' if missing_one_date_filter_field

    urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact
    LOG.debug("URL:" + urlappt)

    response = rescue_service_call 'Appointment Template Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    response = JSON.parse(response)
    
    if using_date_filter
      response = response.map { |template|
        template['appointment_template'][:occurrences] = RecurringTimespan.new(template['appointment_template']).occurences_in_date_range(params[:start_date], params[:end_date])
        if template['appointment_template'][:occurrences].any?
          template
        else
          nil
        end
      }.compact
    end

    body(response.to_json)
    status HTTP_OK
  end

end
