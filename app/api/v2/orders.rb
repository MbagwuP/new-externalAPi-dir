class ApiService < Sinatra::Base

  STATUS = {
    "active" => "active",
    "inactive" => "stopped",
    "created" => "draft",
    "N/A" => "unkown"
  }

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
    @include_intent_target = []
    @include_status_target = []

    @medication = resp['medications'].first
    @medication['status'] = STATUS[@medication['status']]
    status HTTP_OK
    jbuilder :show_medication_order
  end
  get '/v2/medication/:id' do

    medication_id = params[:id]
    business_entity_id = current_business_entity
    base_path = "businesses/#{business_entity_id}/medications/find_by_id.json"
    params = { id: medication_id }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: params,
      rescue_string: 'Medication order'
    )
    @include_intent_target = []
    @include_status_target = []
    @medication_endpoint=true
    @medication = resp['medications'].first
    status HTTP_OK
    jbuilder :show_medication_order
  end
  get '/v2/medications' do
    patient_id = params[:patient_id]
    base_path = "patients/#{patient_id}/medications_list.json"
    parameters = { patient_id: patient_id, intent: params[:intent], status: params[:status]}
    validate_patient_id_param(patient_id)
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: 'Medication order list'
    )
    @medications = resp['medications']
    @medications.each do |medication|
      medication['status'] = STATUS[medication['status']]
    end
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    @include_medication_target = params[:_include] == 'MedicationRequest:medication' ? true : false
    if (params[:intent])
      @include_intent_target=params[:intent].split(",") if params[:intent].include? ","
      @include_intent_target = [params[:intent]]  unless params[:intent].include? ","
    else
      @include_intent_target = []
    end

    if (params[:status])
      @include_status_target=params[:status].split(",") if params[:status].include? ","
      @include_status_target = [params[:status]] unless params[:status].include? ","
    else
      @include_status_target = []
    end

    if params[:_summary] == "count"
      @count_summary =  @medications.entries.length
    end

    status HTTP_OK
    jbuilder :list_medication_orders
  end
end
