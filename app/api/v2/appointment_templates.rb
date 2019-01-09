class ApiService < Sinatra::Base

  # /v2/appointment_templates
  # /v2/appointment_resources/{resource_id}/appointment_templates
  get /\/v2\/appointment_templates|\/v2\/appointment_resources\/(?<resource_id>([0-9]*))\/appointment_templates/ do |resource_id|

    forwarded_params = {resource_id: params[:resource_id], location_id: params[:location_id],
                        status: 'A', include_expanded_info: 'true', use_pagination: 'true', page: params[:page]}

    if date_filter_params?
      validate_date_filter_params!
      forwarded_params.merge!(start_date: params[:start_date], end_date: params[:end_date], include_occurrences:'true')
    end

    urlappt = webservices_uri "appointment_templates/#{current_business_entity}.json",
                              {token: escaped_oauth_token, local_timezone: (local_timezone? ? 'true' : nil)}.merge(forwarded_params).compact
    LOG.debug("URL:" + urlappt)


    response = rescue_service_call 'Appointment Template Look Up' do
      RestClient.get(urlappt, :api_key => APP_API_KEY)
    end

    if !response.headers[:link].nil?
      headers['Link'] = PaginationLinkBuilder.new(response.headers[:link], ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['gateway_url'] + env['PATH_INFO'] + '?' + env['QUERY_STRING']).to_s
    end
    response = JSON.parse(response)

    response = response.map { |template|
      template['appointment_template'].delete('status')
      template['appointment_template']['business_entity_id'] = current_business_entity
      template['appointment_template']['effective_from'] = template['appointment_template']['practice_effective_from']
      template['appointment_template']['effective_to']   = template['appointment_template']['practice_effective_to']
      template['appointment_template']['start_at']       = template['appointment_template']['practice_start_time']
      template['appointment_template']['end_at']         = template['appointment_template']['practice_end_time']
      ['practice_effective_from', 'practice_effective_to', 'practice_start_time', 'practice_end_time'].each do |x|
        template['appointment_template'].delete(x)
      end
      template
    }.compact

    body(response.to_json)
    status HTTP_OK
  end

end
