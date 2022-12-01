class ApiService < Sinatra::Base

  get '/v2/diagnostic_reports' do
    patient_id = params[:patient_id]
    
    validate_patient_id_param(patient_id)

    base_path = "patient_summary/generate_json_by_patient_id_and_component.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, ccd_components: ['labresults'], code: params[:code], category: params[:category],date: params[:date]},
      rescue_string: "Diagnostic report "
    )
    @include_code_target = params[:code] || nil
    @include_category_target = params[:category] || nil
    @include_date_target = params[:date] || nil
    patient_summary = resp['patient_summary']

    patient_summary = JSON.parse(patient_summary) if patient_summary
    diagnostic_reports_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']

    @diagnostic_report = ResultSection.new(diagnostic_reports_section)
    @patient = resp['patient']['patient']
    @lab_results = resp['lab_results'][0]['lab_request_test']

    @business_entity = resp['business_entity']['business_entity']
    @encounter = resp['encounter']['encounter']
    @provider = resp['provider']['provider']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    status HTTP_OK
    jbuilder :list_diagnostic_reports
  end
end
