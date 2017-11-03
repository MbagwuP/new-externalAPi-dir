class ApiService < Sinatra::Base

  post '/v2/patients/:patient_id/eligibility_request' do
    patient_id = params[:patient_id]
    payload = get_request_JSON

    payload['eligibility_date'] ||= DateTime.now.to_s
    url = EligibilityResource.build_eligibility_url(patient_id)
    response = rescue_service_call 'Create Electronic Eligibility Request' do 
      RestClient.post(url, payload, {params: query_string, accept: :json})
    end
  
    body(response)
    status HTTP_CREATED
  end
  
  post '/v2/appointments/:appointment_id/manual_eligibility_request' do
    begin 
      @eligibility_request =  EligibilityResource.create(get_request_JSON,params[:appointment_id],escaped_oauth_token)
    rescue => e
      api_svc_halt e.http_code, e
    end 
    status HTTP_CREATED
    jbuilder :eligibility
  end

  get '/v2/patients/:patient_id/eligibility_request/:id' do
    patient_id = params[:patient_id]
    id = params[:id]

    url = EligibilityResource.build_eligibility_url(patient_id: patient_id, request_id: id)
    if (current_internal_request_header)
      internal_signed_request = sign_internal_request(url: url, method: :get, headers: {accept: :json})
      response = internal_signed_request.execute
    else
      response = RestClient.get(url, {params: query_string, accept: :json})
    end

    body(response)
    status HTTP_OK
  end
end
