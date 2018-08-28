class ApiService < Sinatra::Base

  post '/v2/ccda' do
    ccda_url = webservices_uri(
      "ccda.json",
      token: escaped_oauth_token,
      business_entity_guid: current_business_entity
    )

    response = rescue_service_call 'Create CCDA' do
      RestClient.post(ccda_url, {})
    end

    body response
    status HTTP_OK
  end

  get '/v2/ccda/:ccda_id' do
    ccda_id = params[:ccda_id]
    ccda_url = webservices_uri(
      "ccda/#{ccda_id}.json",
      token: escaped_oauth_token,
      business_entity_id: current_business_entity
    )

    response = rescue_service_call 'Get CCDA' do
      RestClient.get(ccda_url)
    end

    body response
    status HTTP_OK
  end

end
