module Sinatra
  module V2
    module Clinical
      module FormTemplates
        def self.registered(app)
          app.get '/v2/clinical/form-templates/:source/:code' do
            source = params[:source]
            code = params[:code]
            path = "/clinical-data-api/form-templates/#{source}/#{code}"
            url = ApiService::CLINICAL_DATA_API + path

            response = RestClient.get(url, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

            body(response)
            status HTTP_OK
          end

          app.get '/v2/clinical/form-templates/:source/:code/sections' do
            source = params[:source]
            code = params[:code]
            path = "/clinical-data-api/form-templates/#{source}/#{code}/template_sections"
            url = ApiService::CLINICAL_DATA_API + path

            response = RestClient.get(url, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

            body(response)
            status HTTP_OK
          end
        end
      end
    end
  end
  register V2::Clinical::FormTemplates
end
