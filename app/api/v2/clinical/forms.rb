module Sinatra
  module V2
    module Clinical
      module Forms
        module Helpers
          def build_url(patient_id, form_uuid=nil)
            ApiService::CLINICAL_DATA_API + path(patient_id, form_uuid)
          end

          def path(patient_id, form_uuid=nil)
            path = "/clinical-data-api/patients/#{patient_id}/clinical-forms"
            path = "#{path}/#{form_uuid}"if form_uuid
            path
          end
        end

        def self.registered(app)
          app.helpers Forms::Helpers

          app.get '/v2/patients/:patient_id/clinical/forms/:form_uuid' do
            patient_id = params[:patient_id]
            form_uuid = params[:form_uuid]
            url = build_url(patient_id, form_uuid)

            response = RestClient.get(url, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

            body(response)
            status HTTP_OK
          end

          app.put '/v2/patients/:patient_id/clinical/forms/:form_uuid' do
            request_body = get_request_JSON
            patient_id = params[:patient_id]
            form_uuid = params[:form_uuid]
            url = build_url(patient_id, form_uuid)

            response = RestClient.put(url, request_body.to_json, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

            body(response)
            status HTTP_OK
          end

          app.get '/v2/patients/:patient_id/clinical/forms' do
            patient_id = params[:patient_id]
            url = build_url(patient_id)

            response = RestClient.get(url, api_key:  ApiService::APP_API_KEY)

            body(response)
            status HTTP_OK
          end

          app.post '/v2/patients/:patient_id/clinical/forms' do
            request_body = get_request_JSON
            patient_id = params[:patient_id]
            url = build_url(patient_id)
            
            response = RestClient.post(url, request_body.to_json, {params: query_string, api_key:  ApiService::APP_API_KEY, accept: :json})

            body(response)
            status HTTP_OK
          end
        end
      end
    end
  end
  register V2::Clinical::Forms
end
