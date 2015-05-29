class ApiService < Sinatra::Base

  # /v2/resources
  # /v2/appointment/resources (legacy)
  get /\/v2\/(appointment\/resources|appointment_resources)\z/ do
    urlresource = webservices_uri "appointments/#{current_business_entity}/resources.json", token: escaped_oauth_token

    resp = rescue_service_call 'Resource Look Up' do
      RestClient.get(urlresource, :api_key => APP_API_KEY)
    end

    filtered = JSON.parse resp.body
    filtered.each do |x|
      x['resource']['business_entity_id'] = current_business_entity
    end
    filtered = filtered.map{|x| x if x['resource']['status'] == Status::ACTIVE }.compact

    body(filtered.to_json)
    status HTTP_OK
  end

  get '/v2/visit_reasons/:visit_reason_id/appointment_resources' do
    urlresource = webservices_uri "appointments/#{current_business_entity}/resources.json", token: escaped_oauth_token, filter_nature_of_visit_id: params[:visit_reason_id]

    resp = rescue_service_call 'Resource Look Up' do
      RestClient.get(urlresource, :api_key => APP_API_KEY)
    end

    filtered = JSON.parse resp.body
    filtered.each do |x|
      x['resource']['business_entity_id'] = current_business_entity
    end
    filtered = filtered.map{|x| x if x['resource']['status'] == Status::ACTIVE }.compact

    body(filtered.to_json)
    status HTTP_OK
  end

  get '/v2/appointment_resources/:resource_id' do
    urlresource = webservices_uri "businesses/#{current_business_entity}/resources/#{params[:resource_id]}.json",
      token: escaped_oauth_token, include_default_provider: 'true'

    resp = rescue_service_call 'Resource Look Up' do
      RestClient.get(urlresource, :api_key => APP_API_KEY)
    end

    resp = JSON.parse(resp.body)
    api_svc_halt(HTTP_NOT_FOUND, '{"error": "Resource not found."}') if resp['resource']['status'] != Status::ACTIVE
    resp['resource']['business_entity_id'] = current_business_entity
    ['created_by', 'updated_by'].each {|key| resp['resource'].delete(key)}

    body(resp.to_json)
    status HTTP_OK
  end

end
