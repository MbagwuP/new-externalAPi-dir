class ApiService < Sinatra::Base

  # Options
  ########################
  # patient_id
  # date
  # start_date & end_date (YYYY-MM-DD)
  # category
  post '/v2/ccda' do
    params = get_request_JSON.symbolize_keys
    command = ValidateAndBuildCreateCcdaParams.call(
      params,
      token: escaped_oauth_token,
      business_entity_guid: current_business_entity
    )
    if command.success?
      ccda_url = webservices_uri("ccda.json", command.result)
      response = rescue_service_call 'Create CCDA' do
        RestClient.post(ccda_url, {})
      end
      body response
      status HTTP_OK
    else
      api_svc_halt HTTP_BAD_REQUEST, command.errors
    end

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
