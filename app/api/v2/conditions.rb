class ApiService < Sinatra::Base

  get '/v2/conditions/:id' do
    condition_id = params[:id]
    base_path = "assertions/#{condition_id}.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Condition"
    )

    @condition = resp['problems'].first

    status HTTP_OK
    jbuilder :show_condition
  end

  get '/v2/conditions' do
    patient_id = params[:patient_id]
    @acc_number = patient_id
    base_path = "patients/#{patient_id}/problems.json"
    
    validate_patient_id_param(patient_id)

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Conditions"
    )

    @conditions = resp['problems']
    @is_provenance_target_present = params[:_revinclude] == 'Provenance:target' ? true : false

    if params[:_summary] == "count"
      @count_summary =  @conditions.entries.length
    end

    status HTTP_OK
    jbuilder :list_conditions
  end
end
