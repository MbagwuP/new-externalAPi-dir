class ApiService < Sinatra::Base

  post '/v2/patients/:patient_id/eligibility_request' do
    patient_id = params[:patient_id]
    payload = get_request_JSON

    payload['eligibility_date'] ||= DateTime.now.to_s
    url = build_eligibility_url(patient_id)
    response = RestClient.post(url, payload, {params: query_string, accept: :json})

    body(response)
    status HTTP_OK
  end

  get '/v2/patients/:patient_id/eligibility_request/:id' do
    patient_id = params[:patient_id]
    id = params[:id]

    url = build_eligibility_url(patient_id, id)
    if (current_internal_request_header)
      internal_signed_request = sign_internal_request(url: url, method: :get)
      response = internal_signed_request.execute
    else
      response = RestClient.get(url, {params: query_string, accept: :json})
    end

    body(response)
    status HTTP_OK
  end

  def build_eligibility_url(patient_id:, request_id: nil)
    if (current_internal_request_header)
      webservices_uri(eligibility_path(patient_id, request_id))
    else
      webservices_uri(eligibility_path(patient_id, request_id), token: escaped_oauth_token)
    end
  end

  def eligibility_path(patient_id, request_id=nil)
    path = "patients/#{patient_id}/eligibility_request"
    path << "/#{request_id}" if request_id
    path
  end
end
