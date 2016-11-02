class ApiService < Sinatra::Base

  get '/v2/payers' do
    search_criteria = params[:query]
    url = build_payers_url

    response = RestClient.get(url, {params: {search: search_criteria}, accept: :json})

    body(response)
    status HTTP_OK
  end
 
  def build_payers_url()
    webservices_uri(payers_path)
  end

  def payers_path()
    "payers"
  end
end
