class ApiService < Sinatra::Base

  get '/v2/observations' do
    patient_id = params[:patient_id]
    validate_patient_id_param(patient_id)

    base_path = "observations/list_for_cures_act.json"
    parameters = { patient: patient_id, code: params[:code], date: params[:date] }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: "Vital sign"
    )

    body(resp.to_json)
    status HTTP_OK
  end
end