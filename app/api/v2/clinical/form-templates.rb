class ApiService < Sinatra::Base

  get '/v2/clinical/form-templates/:source/:code' do
    source = params[:source]
    code = params[:code]
    path = "/clinical-data-api/form-templates/#{source}/#{code}"
    url = CLINICAL_DATA_API + path

    response = RestClient.get(url, {params: query_string, api_key: APP_API_KEY, accept: :json})

    body(response)
    status HTTP_OK
  end

  get '/v2/clinical/form-templates/:source/:code/sections' do
    source = params[:source]
    code = params[:code]
    path = "/clinical-data-api/form-templates/#{source}/#{code}/template_sections"
    url = CLINICAL_DATA_API + path

    response = RestClient.get(url, {params: query_string, api_key: APP_API_KEY, accept: :json})

    body(response)
    status HTTP_OK
  end

end
