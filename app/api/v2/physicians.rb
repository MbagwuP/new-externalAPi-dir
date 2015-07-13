class ApiService < Sinatra::Base

  get '/v2/physicians/:npi' do

    #http://localservices.carecloud.local:3000/physicians/:npi.json
    urlprovider = webservices_uri "physicians/#{params[:npi]}.json", token: escaped_oauth_token, business_entity_id: current_business_entity
    response = rescue_service_call 'Physician' do
      RestClient.get(urlprovider, :api_key => APP_API_KEY)
    end
    if response == 'null'
      status HTTP_NOT_FOUND
      body({error: "Physician Not Found"}.to_json)
    else
      @physician = JSON.parse(response)['physician']
      status HTTP_OK
      jbuilder :show_physician
    end
  end

end
