class ApiService < Sinatra::Base

  get '/v2/immunizations/:id' do
    immunization_id = params[:id]
    base_path = "immunizations/#{immunization_id}.json"
    
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Immunization'
    )
    
    @immunization = resp['immunizations'].first

    status HTTP_OK
    jbuilder :show_immunization
  end

  get '/v2/immunizations' do
    patinet_id = params[:patient_id]
    base_path = "patients/#{patinet_id}/immunizations.json"
    parameters = { patinet_id: patinet_id }

    validate_patient_id_param(patient_id)
    
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: 'Immunizations'
    )

    @immunizations = resp['immunizations']

    status HTTP_OK
    jbuilder :list_immunizations
  end
end
