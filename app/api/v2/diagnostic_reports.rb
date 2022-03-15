class ApiService < Sinatra::Base

  get '/v2/diagnostic_reports' do
    patient_id = params[:patient_id]
    
    validate_patient_id_param(patient_id)

    base_path = "patient_summary/generate_json_by_patient_id_and_component.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, ccd_components: ['labresults'] },
      rescue_string: "Diagnostic report "
    )

    patient_summary = resp['patient_summary']
    patient_summary = JSON.parse(patient_summary) if patient_summary

    diagnostic_reports_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']

    @diagnostic_report = ResultSection.new(diagnostic_reports_section)
    @patient = resp['patient']['patient']
    @business_entity = resp['business_entity']['business_entity']

    status HTTP_OK
    jbuilder :list_diagnostic_reports
  end
end
