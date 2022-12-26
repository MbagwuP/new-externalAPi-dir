class ApiService < Sinatra::Base

  get '/v2/vital_signs/:id' do
    vital_observation_id = params[:id]
    base_path = "vital_observations/#{vital_observation_id}.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Vital sign"
    )

    @vital_sign = resp['vital_observation']

    status HTTP_OK
    jbuilder :show_vital_sign
  end

  get '/v2/vital_signs' do
    patient_id = params[:patient_id]
    validate_patient_id_param(patient_id)

    base_path = "vital_observations/list_by_patient.json"
    parameters = { patient_id: patient_id }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: "Vital sign"
    )

    @vital_signs = resp['vital_observations']

    status HTTP_OK
    jbuilder :list_vital_signs
  end
end