class ApiService < Sinatra::Base

  get '/v2/smoking_statuses' do
    patient_id = params[:patient_id]
    
    validate_patient_id_param(patient_id)

    base_path = "patient_summary/generate_json_by_patient_id_and_component.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, ccd_components: ['social_history'] },
      rescue_string: "Smoking status "
    )

    patient_summary = resp['patient_summary']
    patient_summary = JSON.parse(patient_summary) if patient_summary

    social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
   
    @social_history = SocialHistorySection.new(social_history_section)
    @patient = resp['patient'] ? resp['patient']['patient']: nil
    @business_entity = resp['business_entity'] ? resp['business_entity']['business_entity'] : nil

    status HTTP_OK
    jbuilder :list_smoking_status
  end
end
