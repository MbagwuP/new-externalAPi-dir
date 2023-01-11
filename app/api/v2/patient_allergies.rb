class ApiService < Sinatra::Base

  get '/v2/allergy_intolerances/:id' do
    allergy_intolerance_id = params[:id]
    base_path = "patient_allergies/#{allergy_intolerance_id}.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Allergy"
    )
    @allergy = resp['allergies']
    status HTTP_OK
    jbuilder :show_allergy_intolerance
  end

  get '/v2/allergy_intolerances' do
    patient_id = params[:patient_id]
    patient_status = params[:status]
    validate_patient_id_param(patient_id)

    base_path = "patient_allergies/list_by_patient.json"
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, status: patient_status},
      rescue_string: "Allergy list"
    )

    @allergies = resp['allergies']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    if params[:_summary] == "count"
      @count_summary =  @allergies.length
    end
    status HTTP_OK
    jbuilder :list_allergy_intolerance
  end
end