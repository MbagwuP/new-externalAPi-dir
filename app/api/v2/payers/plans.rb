class ApiService < Sinatra::Base

  get '/v2/payers/:payer_id/plans' do
    payer_id = params[:payer_id]
    url = build_payer_plans_url(payer_id)

    response = RestClient.get(url, {accept: :json})

    body(response)
    status HTTP_OK
  end
 
  def build_payer_plans_url(payer_id)
    webservices_uri(payer_plans_path(payer_id), token: escaped_oauth_token)
  end

  def payer_plans_path(payer_id)
    "payers/#{payer_id}/plans"
  end
end
