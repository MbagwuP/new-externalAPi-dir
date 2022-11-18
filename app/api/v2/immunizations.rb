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
    patient_id = params[:patient_id]
    patient_status = params[:status]
    date_param = params[:date]

    base_path = "patients/#{patient_id}/immunizations.json"
    validate_patient_id_param(patient_id)
    if date_param.present?
      date_param = validate_date_param(date_param)
    end
    
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, status: patient_status, date: date_param },
      rescue_string: 'Immunizations'
    )
    
    @immunizations = resp['immunizations']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    status HTTP_OK
    jbuilder :list_immunizations
  end
end
