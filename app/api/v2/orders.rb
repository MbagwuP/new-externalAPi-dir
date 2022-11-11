class ApiService < Sinatra::Base

  get '/v2/medications/:id' do
    medication_id = params[:id]
    business_entity_id = current_business_entity
    base_path = "businesses/#{business_entity_id}/medications/find_by_id.json"
    params = { id: medication_id }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: params,
      rescue_string: 'Medication order'
    )

    @medication = resp['medications'].first
    status HTTP_OK
    jbuilder :show_medication_order
  end

  get '/v2/medications' do
    patient_id = params[:patient_id]
    base_path = "patients/#{patient_id}/medications_list.json"

    validate_patient_id_param(patient_id)
    
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Medication order list'
    )
    @medications = resp['medications']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    status HTTP_OK
    jbuilder :list_medication_orders
  end
end
