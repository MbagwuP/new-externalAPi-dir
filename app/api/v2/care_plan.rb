class ApiService < Sinatra::Base

  get '/v2/care_plans' do
    patient_id = params[:patient_id]
    
    validate_patient_id_param(patient_id)

    base_path = "patient_summary/generate_json_by_patient_id_and_component.json"
  
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, ccd_components: ['plan_of_treatment'] },
      rescue_string: "Care Plans "
    )

    patient_summary = resp['patient_summary']
    patient_summary = JSON.parse(patient_summary) if patient_summary

    plan_of_treatment_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
    
    @plan_of_treatment = PlanOfTreatmentSection.new(plan_of_treatment_section)
    @patient = resp['patient']['patient']
    @business_entity = resp['business_entity']['business_entity']

    status HTTP_OK
    jbuilder :list_care_plans
  end
end
