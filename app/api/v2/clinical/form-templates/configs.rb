module Sinatra
  module V2
    module Clinical
      module FormTemplates
        module Configs
          module Helpers
            def build_url(entityId,id=nil)
              ApiService::CLINICAL_DATA_API + path(entityId,id)
            end

            def path(entityId,id=nil)
              path = "/clinical-data-api/business-entities/#{entityId}/form-template-configs"
              path = "#{path}/#{id}" if id
              path
            end

            def entity_id
              params[:entityId]
            end

            def id
              params[:id]
            end

          end

          def self.registered(app)
            app.helpers Configs::Helpers

            app.get '/v2/business-entity/:entityId/clinical/form-templates/configs' do
              response = RestClient.get(build_url(entity_id), {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})
              
              body(response)
              status HTTP_OK
            end

            app.post '/v2/business-entity/:entityId/clinical/form-templates/configs' do
              request_body = get_request_JSON

              response = RestClient.post(build_url(entity_id), request_body.to_json, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

              body(response)
              status HTTP_OK
            end

            app.get '/v2/business-entity/:entityId/clinical/form-templates/configs/:id' do
              response = RestClient.get(build_url(entity_id,id), {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

              body(response)
              status HTTP_OK
            end

            app.put '/v2/business-entity/:entityId/clinical/form-templates/configs/:id' do
              request_body = get_request_JSON

              response = RestClient.put(build_url(entity_id,id), request_body.to_json, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

              body(response)
              status HTTP_OK
            end
          end
        end
      end
    end
  end
  register V2::Clinical::FormTemplates::Configs
end
