class ApiService < Sinatra::Base

  get '/v2/conditions/:id' do
    condition_id = params[:id]
    condition_url = webservices_uri "assertions/#{condition_id}.json",
                                    { token: escaped_oauth_token }

    @resp = rescue_service_call 'Condition' do
      RestClient.get(condition_url)
    end
  
    @resp = JSON.parse(@resp)
    
    @condition = @resp['problems'].first

    status HTTP_OK
    jbuilder :show_condition
  end
end
