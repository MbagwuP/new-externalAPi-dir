class ApiService < Sinatra::Base

  # /v2/resources
  # /v2/appointment/resources (legacy)
  get /\/v2\/(appointment\/resources|appointment_resources)\z/ do
    urlresource = webservices_uri "appointments/#{current_business_entity}/resources.json", token: escaped_oauth_token

    resp = rescue_service_call 'Resource Look Up' do
      RestClient.get(urlresource, :api_key => APP_API_KEY)
    end

    body(resp.body)
    status HTTP_OK
  end

  get '/v2/appointment_resources/:resource_id' do
    urlresource = webservices_uri "businesses/#{current_business_entity}/resources/#{params[:resource_id]}.json",
      token: escaped_oauth_token, include_default_provider: 'true'

    resp = rescue_service_call 'Resource Look Up' do
      RestClient.get(urlresource, :api_key => APP_API_KEY)
    end

    resp = JSON.parse(resp.body)
    ['created_by', 'updated_by'].each {|key| resp['resource'].delete(key)}

    body(resp.to_json)
    status HTTP_OK
  end

end
