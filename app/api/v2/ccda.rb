class ApiService < Sinatra::Base

  # Options
  ########################
  # patient_id
  # date
  # start_date & end_date (YYYY-MM-DD)
  # category
  #DO NOT MODIFY ENDPOINT - was ONC Certified.
  post '/v2/ccda' do
    query_args = params || {}
    args = get_request_JSON.symbolize_keys.merge(query_args).with_indifferent_access
    command = ValidateAndBuildCreateCcdaParams.call(
      args,
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
    
  post /\/v2\/patients\/(?<patient_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/(ccda)$/ do
    query_args = params || {}
    args = get_request_JSON.symbolize_keys.merge(query_args).with_indifferent_access
    args["scoped_request"] = true
    command = ValidateAndBuildCreateCcdaParams.call(
      args,
      token: escaped_oauth_token,
      business_entity_guid: current_business_entity
    )
    if command.success?
      ccda_url = webservices_uri("ccda.json", command.result)
      response = rescue_service_call 'Create Patient CCDA' do
        RestClient.post(ccda_url, {})
      end
      resp = JSON.parse(response)
      resp["ccda_request"]["business_entity_id"] = current_business_entity
      resp["ccda_request"]["status"]["time"] = convert_secs_to_string(resp["ccda_request"]["status"]["time"]) if resp["ccda_request"]["status"]

      status HTTP_OK
      body(resp.to_json)
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

    response  = rescue_service_call 'Get CCDA' do
      RestClient.get(ccda_url)
    end
  
    resp = JSON.parse(response)
    resp["ccda_request"]["status"]["time"] = convert_secs_to_string(resp["ccda_request"]["status"]["time"]) if resp["ccda_request"]["status"]
    resp["ccda_request"]["business_entity_id"] = current_business_entity

    status HTTP_OK
    body(resp.to_json)
  end
  
  private 
  
  def convert_secs_to_string(secs)
     Time.at(secs).to_datetime rescue secs
  end 

end
