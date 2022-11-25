class ApiService < Sinatra::Base

	#input patient_id , type
  #optional input - ccd_components, date ,status , summary
  #type - Type of resource
	#ccd_component - For patient summary request(Goals and smoking status)
	def get_response(patient_id,type,options={})
		base_path = get_base_path(type,patient_id)
		params = {}
    params[:patient_id] = patient_id
    params[:ccd_components] = options[:ccd_component] if options[:ccd_component].present?
    params[:date] = options[:date] if options[:date].present?
    params[:status] = options[:status] if options[:status].present?

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: params,
      rescue_string: type
    )

    result_hash = {}
    
    case type
    when 'Goal'
    	patient_summary = resp['patient_summary']
    	patient_summary = JSON.parse(patient_summary) if patient_summary
    	goals_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']    
    	resources = GoalSection.new(goals_section)
    	patient = resp['patient']['patient']
	    business_entity = resp['business_entity']['business_entity']
	    provider = resp['provider']
	    contact = resp['contact']
	    result_hash[:resources] = resources
	    result_hash[:patient] = patient
	    result_hash[:provider] = provider
	    result_hash[:contact] = contact
	    result_hash[:business_entity] = business_entity
    when 'Smoking Status'
    	patient_summary = resp['patient_summary']
    	patient_summary = JSON.parse(patient_summary) if patient_summary
    	social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']   
      resources = SocialHistorySection.new(social_history_section)
      patient = resp['patient']['patient']
	    business_entity = resp['business_entity']['business_entity']
	    provider = resp['provider']
	    contact = resp['contact']
	    result_hash[:resources] = resources
	    result_hash[:patient] = patient
	    result_hash[:provider] = provider
	    result_hash[:contact] = contact
	    result_hash[:business_entity] = business_entity
	  when 'Immunization'
	   	immunizations = resp['immunizations']
	   	result_hash[:resources] = immunizations
		when 'Condition'
			result_hash[:resources] = resp['problems']
		when 'Careplan'
      patient_summary = resp['patient_summary']
      patient_summary = JSON.parse(patient_summary) if patient_summary
      plan_of_treatment_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
      resources = PlanOfTreatmentSection.new(plan_of_treatment_section)
      result_hash[:resources] = resources
      result_hash[:patient] = resp['patient']['patient']
      result_hash[:provider] = resp['provider']
      result_hash[:contact] = resp['contact']
      result_hash[:business_entity] = resp['business_entity']['business_entity']

      if options[:summary] == "count"
        result_hash[:count_summary] = resources.entries.length
      end
		else
	  end
    result_hash
	end

	def get_base_path(type,patient_id)
		case type
		when 'Goal'
			"patient_summary/generate_json_by_patient_id_and_component.json"
		when 'Smoking Status'
			"patient_summary/generate_json_by_patient_id_and_component.json"
		when "Immunization"
			"patients/#{patient_id}/immunizations.json"
		when "Condition"
			"patients/#{patient_id}/problems.json"
		when "Careplan"
			"patient_summary/generate_json_by_patient_id_and_component.json"
		else
		end
	end

  def group_patients(group_id)
		base_path = "patient-groups/list-patients-by-group.json?"

		resp = evaluate_current_internal_request_header_and_execute_request(
				base_path: base_path,
				params: {group_id: group_id},
				rescue_string: 'PatientGroups'
		)
   	resp
	end
end