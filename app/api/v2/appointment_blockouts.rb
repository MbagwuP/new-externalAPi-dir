class ApiService < Sinatra::Base

  get '/v2/appointment_blockouts' do

    forwarded_params = {
      resource_id: params[:resource_id],
      location_id: params[:location_id]
    }
    
    # end_date is mandatory for date filtering; start date is not
    if date_filter_params?
      params[:start_date] = Date.today.to_s if params[:start_date].blank?
      validate_date_filter_params!(require_only_end: true)
      forwarded_params[:from] = params[:start_date]
      forwarded_params[:to] = params[:end_date]
    end
    
    # in Webservices: AppointmentBlockoutsController#list_by_business_entity
    urlappt = webservices_uri "appointment_blockouts/#{current_business_entity}.json",
                              {token: escaped_oauth_token, include_resources_and_locations: params[:include_resources_and_locations],local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact
    @blockouts = rescue_service_call 'Appointment Blockout Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end
    
    @current_business_entity_id = current_business_entity
    @blockouts = JSON.parse(@blockouts)
    jbuilder :list_appointment_blockouts
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
