class ApiService < Sinatra::Base

  get '/v2/allergy_intolerance/:id' do
    allergy_intolerance_id = params[:id]
    base_path = "patient_allergies/#{allergy_intolerance_id}.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Allergy"
    )

    @allergy = resp['allergies'].first

    status HTTP_OK
    jbuilder :show_allergy_intolerance
  end

  get '/v2/allergy_intolerances' do
    patient_id = params[:patient_id]
    validate_patient_id_param(patient_id)

    base_path = "patient_allergies/list_by_patient.json"
    params = { patient_id: patient_id }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: params,
      rescue_string: "Allergy list"
    )

    @allergies = resp['allergies']

    status HTTP_OK
    jbuilder :list_allergy_intolerance
  end
end