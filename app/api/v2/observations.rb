class ApiService < Sinatra::Base

  get '/v2/observations' do
    patient_id = params[:patientid]
    validate_patient_id_param(patient_id)

    base_path = get_observations_path(params[:code])
    parameters = { patient_id: patient_id, code: params[:code], date: params[:date], ccd_components: ['social_history'] }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: "Observation"
    )
    case params[:code]
    when "5778-6"
      @lab_results = resp['lab_request_test_results']
      status HTTP_OK
      jbuilder :list_lab_results
    when "72166-2"
      patient_summary = resp['patient_summary']
      patient_summary = JSON.parse(patient_summary) if patient_summary

      social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
   
      @social_history = SocialHistorySection.new(social_history_section)
      @patient = resp['patient']['patient']
      @business_entity = resp['business_entity']['business_entity']
      @provider = resp['provider']
      @contact = resp['contact']
      status HTTP_OK
      jbuilder :list_observations_smoking_status
    else
      @observation_entries = resp['observations']
      status HTTP_OK
      jbuilder :list_observations
    end
  end
end