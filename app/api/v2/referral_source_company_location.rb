class ApiService < Sinatra::Base

  get '/v2/referral_location/search' do
    forwarded_params = {search: params[:name]}
    urlreferrallocation = webservices_uri "referral_location/search.json", {token: escaped_oauth_token, current_business_entity_id:current_business_entity}.merge(forwarded_params)

    @resp = rescue_service_call 'Referral Location Transactions Look Up' do
      RestClient.get(urlreferrallocation, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    status HTTP_OK
    jbuilder :list_referral_location
  end

  post '/v2/referral_location/create' do
    request_body = get_request_JSON
    @phone_type_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::PhoneType, request_body['phone']['phone_type_code'])
    request_body['phone']['phone_type_id']  = @phone_type_id
    @state_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::State, request_body['address']['state_code'])
    request_body['address']['state_id']  = @state_id
    @country_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::Country, request_body['address']['country_name'])
    request_body['address']['country_id']  = @country_id

    urlreferrallocationcreate = webservices_uri "referral_location/create.json", {token: escaped_oauth_token, current_business_entity_id:current_business_entity}
    begin
      response = RestClient.post(urlreferrallocationcreate, request_body,
        {:content_type => :json, :api_key => APP_API_KEY})
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Referral Location Creation Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed = JSON.parse(response.body)
    the_response_hash = {:referral_location => parsed['referral_location']['id'].to_s}
    body(the_response_hash.to_json)
    status HTTP_CREATED
end


get '/v2/referral_source/search' do
  forwarded_params = {search: params[:name], referral_source_type_id: params[:referral_source_type_id]}
  urlreferrallocation = webservices_uri "referring_physician/search_by_business_entity.json", {token: escaped_oauth_token, current_business_entity_id:current_business_entity}.merge(forwarded_params)

  response = rescue_service_call 'Referral Source Transactions Look Up' do
    RestClient.get(urlreferrallocation, :api_key => APP_API_KEY)
  end
  @parsed = JSON.parse(response)
  status HTTP_OK
  jbuilder :list_referral_source
end

post '/v2/referral_source/create' do
  request_body = get_request_JSON
  @phone_type_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::PhoneType, request_body['phone']['phone_type_code'])
  request_body['phone']['phone_type_id']  = @phone_type_id
  @state_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::State, request_body['address']['state_code'])
  request_body['address']['state_id']  = @state_id
  @country_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::Country, request_body['address']['country_name'])
  request_body['address']['country_id']  = @country_id

  urlreferralsourcecreate = webservices_uri "referring_physician/create.json", {token: escaped_oauth_token, current_business_entity_id:current_business_entity}
  begin
    response = RestClient.post(urlreferralsourcecreate, request_body,
      {:content_type => :json, :api_key => APP_API_KEY})
  rescue => e
    begin
      exception = error_handler_filter(e.response)
      errmsg = "Referral Source Creation Failed - #{exception}"
      api_svc_halt e.http_code, errmsg
    rescue
      api_svc_halt HTTP_INTERNAL_ERROR, errmsg
    end
  end
  parsed = JSON.parse(response.body)
  the_response_hash = {:referral_source => parsed['referring_physician']['id']}
  body(the_response_hash.to_json)
  status HTTP_CREATED
end

 
end
