class ApiService < Sinatra::Base

  # /v2/resources
  # /v2/appointment/resources (legacy)
  get /\/v2\/(appointment\/resources|resources)/ do
    urlresource = webservices_uri "appointments/#{current_business_entity}/resources.json", token: escaped_oauth_token

    resp = rescue_service_call 'Resource Look Up' do
      RestClient.get(urlresource, :api_key => APP_API_KEY)
    end

    body(resp.body)
    status HTTP_OK
  end

end
