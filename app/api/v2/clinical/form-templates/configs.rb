class ApiService < Sinatra::Base

  get '/v2/business-entity/:entityId/clinical/form-templates/configs' do
    response = RestClient.get(build_config_url(entity_id), api_key: APP_API_KEY)
    
    body(response)
    status HTTP_OK
  end

  post '/v2/business-entity/:entityId/clinical/form-templates/configs' do
    request_body = get_request_JSON

    response = RestClient.post(build_config_url(entity_id), request_body.to_json, api_key: APP_API_KEY)

    body(response)
    status HTTP_OK
  end

  get '/v2/business-entity/:entityId/clinical/form-templates/configs/:id' do
    response = RestClient.get(build_config_url(entity_id,id), api_key: APP_API_KEY)

    body(response)
    status HTTP_OK
  end

  put '/v2/business-entity/:entityId/clinical/form-templates/configs/:id' do
    request_body = get_request_JSON

    response = RestClient.put(build_config_url(entity_id,id), request_body.to_json, api_key: APP_API_KEY)

    body(response)
    status HTTP_OK
  end

  def entity_id
    @entity_id ||= params[:entityId]
  end

  def id
    @id ||= params[:id]
  end

  def build_config_url(entityId,id=nil)
    CLINICAL_DATA_API + config_path(entityId,id)
  end

  def config_path(entityId,id=nil)
    path = "/clinical-data-api/form-template-configs/#{entityId}"
    "#{path}/#{id}" if id
    path
  end

end
