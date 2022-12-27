class ApiService < Sinatra::Base

  get '/v2/procedures/:id' do
    procedure_id = params[:id]

    base_path = "procedure_orders/find_by_id.json"
    parameters = { id: procedure_id }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: 'Procedures '
    )

    @procedure = resp['procedure_order']

    status HTTP_OK
    jbuilder :show_procedure
  end

  get '/v2/procedures' do
    patient_id = params[:patient_id]
    base_path = "procedure_tests/list_by_patient.json"
    parameters = { patient_id: patient_id }
    
    validate_patient_id_param(patient_id)

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: 'Procedures list ',
    )

    @procedures = resp['procedures']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    if params[:_summary] == "count"
      @count_summary =  @procedures.entries.length
    end

    status HTTP_OK
    jbuilder :list_procedures
  end
end