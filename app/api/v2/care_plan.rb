class ApiService < Sinatra::Base


  get '/v2/careplan/:id' do

    @care_plan_id = params[:id]

    splited_params_ids= @care_plan_id.split("-CarePlan-")
    validate_patient_id_param(splited_params_ids[0])

    base_path = "patient_summary/generate_json_by_patient_id_and_component.json"
  
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: splited_params_ids[0], ccd_components: ['plan_of_treatment'] },
      rescue_string: "Care Plans "
    )

    patient_summary = resp['patient_summary']
    patient_summary = JSON.parse(patient_summary) if patient_summary

    plan_of_treatment_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']

    @plan_of_treatment = PlanOfTreatmentSection.new(plan_of_treatment_section).entries[splited_params_ids[1].to_i-1]
    @patient = resp['patient'] ? resp['patient']['patient'] : nil

    if params[:_summary] == "count"
      @count_summary =  @plan_of_treatment.entries.length
    end
    @contact = resp['contact']

    @business_entity = resp['business_entity'] ? resp['business_entity']['business_entity'] : nil
    @provider = resp['provider']

    status HTTP_OK
    jbuilder :show_care_plan
  end

  get '/v2/careplan' do
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
    @contact = resp['contact']
    @patient = resp['patient'] ? resp['patient']['patient']  : nil
    @provider= resp['provider'] ? resp['provider']['provider'] : nil

    @business_entity = resp['business_entity'] ? resp['business_entity']['business_entity'] : nil

    if params[:_summary] == "count"
      @count_summary =  @plan_of_treatment.entries.length
    end
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    status HTTP_OK
    jbuilder :list_care_plans
  end
end
