class ApiService < Sinatra::Base

  get '/v2/medications/:id' do
    medication_id = params[:id]
    business_entity_id = current_business_entity
    mediation_url = webservices_uri "businesses/#{business_entity_id}/medications/find_by_id.json",
                                    { id: medication_id, token: escaped_oauth_token }

    @resp = rescue_service_call 'Medication order' do
      RestClient.get(mediation_url, api_key: APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    @medication = @resp['medications'].first

    status HTTP_OK
    jbuilder :show_medication_order
  end

  get '/v2/medications' do
    patient_id = params[:patient_id]
    api_svc_halt HTTP_BAD_REQUEST, '{error: Missing required patient_id params.}' unless patient_id

    mediation_order_list_url = webservices_uri "patients/#{patient_id}/medications_list.json",
                                               { token: escaped_oauth_token }

    @resp = rescue_service_call 'Medication order list' do
      RestClient.get(mediation_order_list_url, api_key: APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    @medications = @resp['medications']

    status HTTP_OK
    jbuilder :list_medication_orders
  end
end
