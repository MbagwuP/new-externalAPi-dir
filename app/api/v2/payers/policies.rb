class ApiService < Sinatra::Base

  get '/v2/payers/:payer_id/policies' do
    payer_id = params[:payer_id]
    url = build_payer_policy_url(payer_id)

    response = RestClient.get(url, {accept: :json})

    body(response)
    status HTTP_OK
  end
 
  def build_payer_policy_url(payer_id)
    webservices_uri(payer_policy_path(payer_id), token: escaped_oauth_token)
  end

  def payer_policy_path(payer_id)
    "payers/#{payer_id}/policy_types"
  end
end
