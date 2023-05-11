class ApiService < Sinatra::Base

  get '/v2/referral_location/search' do
    forwarded_params = {search: params[:name]}
    urlreferrallocation = webservices_uri "referral_location/search.json", {token: escaped_oauth_token, current_business_entity_id:current_business_entity}.merge(forwarded_params)

    @resp = rescue_service_call 'Referral Location Transactions Look Up' do
      RestClient.get(urlreferrallocation, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    @resp.each do |resphone|
      resphone['phones'] = []
      resphone['phones'].push({
             "phone_number" => resphone['phone']['phone']['phone_number'],
             "phone_type_code" => WebserviceResources::Converter.cc_id_to_code(WebserviceResources::PhoneType, resphone['phone']['phone']['phone_type_id']),
             "phone_ext" => resphone['phone']['phone']['phone_ext'] || resphone['phone']['phone']['extension']
           })

      resphone['phones'].push({
        "phone_number" => resphone['fax'],
        "phone_type_code" => "F",
        "phone_ext" => nil
      }) if resphone['fax']
    end
  
    status HTTP_OK
    jbuilder :list_referral_location
  end

  post '/v2/referral_location/create' do
    request_body = get_request_JSON

    error_message = validate_phone_and_fax(request_body)
    if error_message 
      errmsg = "Referral Location Creation Failed - The phones array must contain 2 elements. A phone number for a fax machine, and a phone number associated to the location"
      api_svc_halt HTTP_BAD_REQUEST, errmsg
    end

    @state_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::State, request_body['address']['state_code'])
    request_body['address']['state_id']  = @state_id
    @country_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::Country, "USA")
    request_body['address']['country_id']  = @country_id
    request_body["phones"].each {
        |phone| 
        if phone["phone_type_code"] == "F"
          request_body['fax']  = phone["phone_number"]
          phone.delete('phone_number')
          phone.delete('phone_type_code')
          phone.delete('extension')
        else
          phone["phone_type_id"] = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::PhoneType, phone["phone_type_code"]) 
        end
      
    }
    request_body['is_active']  = true
    request_body.rename_key('phones', 'phone')
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
    the_response_hash = {:location_id => parsed['referral_location']['id'].to_s}
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
  @parsed.each do |resphone|
    resphone['phones'] = []
    resphone['phones'].push({
           "phone_number" => resphone['phone']['phone']['phone_number'],
           "phone_type_code" => WebserviceResources::Converter.cc_id_to_code(WebserviceResources::PhoneType, resphone['phone']['phone']['phone_type_id']),
           "phone_ext" => resphone['phone']['phone']['phone_ext'] || resphone['phone']['phone']['extension']
         })

    resphone['phones'].push({
      "phone_number" => resphone['fax'],
      "phone_type_code" => "F",
      "phone_ext" => nil
    }) if resphone['fax']
  end

  status HTTP_OK
  jbuilder :list_referral_source
end

post '/v2/referral_source/create' do
  request_body = get_request_JSON
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

private

def validate_phone_and_fax(request_body)
  phone_type_codes = []
  fax = nil
  request_body["phones"].each do |phone|
    if phone["phone_type_code"] == "M" or phone["phone_type_code"] == "P" or phone["phone_type_code"] == "C" or phone["phone_type_code"] == "H" or phone["phone_type_code"] == "B"
      phone_type_codes << phone["phone_type_code"]
    elsif phone["phone_type_code"] == "F"
      fax = phone
    end
  end
 
  if fax.nil?
    return "Fax is missing"
  elsif phone_type_codes.empty?
    return "Phone is missing"
  end
end
end
