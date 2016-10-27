class ApiService < Sinatra::Base

  post '/v2/patients/:patient_id/eligibility_request' do
    patient_id = params[:patient_id]
    payload = get_request_JSON

    payload['eligibility_date'] ||= DateTime.now.to_s
    url = build_eligibility_url(patient_id)
    response = RestClient.post(url, payload, {accept: :json})

    body(response)
    status HTTP_OK
  end

  get '/v2/patients/:patient_id/eligibility_request/:id' do
    patient_id = params[:patient_id]
    id = params[:id]

    url = build_eligibility_url(patient_id, id)
    response = RestClient.get(url, {accept: :json})

    body(response)
    status HTTP_OK
  end 
 
  def build_eligibility_url(patient_id, request_id=nil)
    webservices_uri(eligibility_path(patient_id, request_id), token: escaped_oauth_token)
  end

  def eligibility_path(patient_id, request_id=nil)
    path = "patients/#{patient_id}/eligibility_request"
    path << "/#{request_id}" if request_id
    path
  end
end
