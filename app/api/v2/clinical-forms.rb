class ApiService < Sinatra::Base

  get '/v2/clinical/forms/:source/:type' do
    source = params[:source]
    type = params[:type]
    path = "clinical-data-api/form-templates/#{source}/#{type}"
    url = CLINICAL_DATA_API + path

    response = RestClient.get(url, :api_key => APP_API_KEY)

    body(response)
    status HTTP_OK
  end

end
