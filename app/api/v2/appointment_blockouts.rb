class ApiService < Sinatra::Base

  get '/v2/appointment_blockouts' do
    forwarded_params = {resource_id: params[:resource_id], location_id: params[:location_id], start_date: params[:start_date], end_date: params[:end_date]}

    params_error = ParamsValidator.new(params, :invalid_date_passed, :blank_date_field_passed, :missing_one_date_filter_field, :date_filter_range_too_long).error
    api_svc_halt HTTP_BAD_REQUEST, params_error if params_error.present?

    using_date_filter = params[:start_date] && params[:end_date]
    if !using_date_filter
      forwarded_params[:from] = Date.today.to_s
      forwarded_params[:to] = Date.today.to_s
    end

    urlappt = webservices_uri "appointment_blockouts/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact

    response = rescue_service_call 'Appointment Blockout Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end
    response = JSON.parse(response)

    
    # fetch the BE's details, we need its local timezone
    urlbusentity = webservices_uri "businesses/#{current_business_entity}.json",
                                   {token: escaped_oauth_token, include_timezone: 'true', business_entity_id: current_business_entity}
    busentity = rescue_service_call 'Practice Look Up' do
      RestClient.get(urlbusentity)
    end
    busentity = JSON.parse(busentity)

    response = response.map {|blockout|
      blockout['appointment_blockout']['business_entity_id'] = current_business_entity
      blockout['appointment_blockout']['timezone_name'] = busentity['business_entity']['timezone']['name']
      recurring_timespan = RecurringTimespan.new(blockout['appointment_blockout'])

      blockout['appointment_blockout'].delete('start_hour')
      blockout['appointment_blockout'].delete('end_hour')
      blockout['appointment_blockout'].delete('start_minutes')
      blockout['appointment_blockout'].delete('end_minutes')
      blockout['appointment_blockout'].delete('created_by')
      blockout['appointment_blockout'].delete('updated_by')
      blockout['appointment_blockout'].delete('start_hour_bak')
      blockout['appointment_blockout'].delete('end_hour_bak')
      blockout['appointment_blockout']['effective_from'] = recurring_timespan.effective_from_iso8601_date
      blockout['appointment_blockout']['effective_to'] = recurring_timespan.effective_to_iso8601_date
      blockout['appointment_blockout']['start_at'] = recurring_timespan.practice_start_time
      blockout['appointment_blockout']['end_at'] = recurring_timespan.practice_end_time

      if using_date_filter
        blockout['appointment_blockout'][:occurrences] = recurring_timespan.occurences_in_date_range(params[:start_date], params[:end_date])
        if blockout['appointment_blockout'][:occurrences].any?
          blockout
        else
          nil # don't return blockouts that have no occurences in specified date range
        end
      else
        blockout # no date range was specified, so return all blockouts
      end
    }.compact

    body(response.to_json)
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
      appointments_data.each { |x|
        x['appointment']['id'] = x['appointment']['external_id']
        x['appointment'].rename_key('nature_of_visit_id', 'visit_reason_id')
      }
      data['appointments'] = appointments_data
    end

    body(data.to_json)
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

end
