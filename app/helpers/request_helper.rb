class ApiService < Sinatra::Base

	#input patient_id , type
  #optional input - ccd_components, date ,status , summary
  #type - Type of resource
	#ccd_component - For patient summary request(Goals and smoking status)
	def get_response(patient_id,type,options={})
		base_path = get_base_path(type,patient_id,{code: options[:code]})

		params = {}
    params[:patient_id] = patient_id
    params[:ccd_components] = options[:ccd_components] if options[:ccd_components].present?
    params[:date] = options[:date] if options[:date].present?
    params[:status] = options[:status] if options[:status].present?
    params[:code] = get_observations_code(options[:code]) if options[:code].present?
    params[:name] = options[:name] if options[:name].present?
    params[:dob] = options[:dob] if options[:dob].present?
    params[:gender] = options[:gender] if options[:gender].present?
    params[:mrn] =  options[:mrn] if options[:mrn].present?
    params[:intent] = options[:intent] if options[:intent].present?

    params[:scope] = options[:scope] if options[:scope].present?

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
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
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
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
	  when 'Immunization'
	   	immunizations = resp['immunizations']
	   	result_hash[:resources] = immunizations
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
		when 'Encounter'
			result_hash[:resources] = resp['encounters']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
		when 'Condition'
			result_hash[:resources] = resp['problems']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
    when 'Patient'
      result_hash[:resources] = resp['patients']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
		when 'CarePlan'
      patient_summary = resp['patient_summary']
      patient_summary = JSON.parse(patient_summary) if patient_summary
      plan_of_treatment_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
      resources = PlanOfTreatmentSection.new(plan_of_treatment_section)
      result_hash[:resources] = resources
      result_hash[:patient] = resp['patient']['patient']
      result_hash[:provider] = resp['provider']
      result_hash[:contact] = resp['contact']
      result_hash[:business_entity] = resp['business_entity']['business_entity']

      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = resources.entries.length
      end
    when 'CareTeam'
      result_hash[:resources] = resp['care_team_members']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].length
      end
    when 'Device'
      result_hash[:resources] = resp.map { |e| e['implantable_device'] }
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].length
      end
    when 'Procedure'
      result_hash[:resources] = resp['procedures']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
    when 'MedicationRequest'
      result_hash[:resources] = resp['medications']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
    when 'Medication'
      result_hash[:resources] = resp['medications']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].entries.length
      end
    when 'DocumentReference'
      result_hash[:resources] = resp['documents']

      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].length
      end
    when 'DiagnosticReport'
      patient_summary = resp['patient_summary']
      patient_summary = JSON.parse(patient_summary) if patient_summary
      diagnostic_reports_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']

      result_hash[:resources] = ResultSection.new(diagnostic_reports_section)

      result_hash[:encounter] = resp['encounter']['encounter']
      result_hash[:provider] = resp['provider']['provider']
      result_hash[:patient] = resp['patient']['patient']
      result_hash[:lab_results] = resp['lab_requests']
      result_hash[:business_entity] = resp['business_entity']['business_entity']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:lab_results].length
      end
    when 'AllergyIntolerance'
      result_hash[:resources] = resp['allergies']
      if options[:summary] == "count" || options[:resource_counts] == "true"
        result_hash[:count_summary] = result_hash[:resources].length
      end
    when 'Observation'

      if options[:code] == ObservationCode::LABORATORY || options[:category] == 'laboratory'
        result_hash[:resources] = resp
        if options[:summary] == "count" || options[:resource_counts] == "true"
          result_hash[:count_summary] =  result_hash[:resources].entries.length
        end
      elsif options[:code] == ObservationCode::SMOKING_STATUS
        patient_summary = resp['patient_summary']
        patient_summary = JSON.parse(patient_summary) if patient_summary

        social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
        @social_history = SocialHistorySection.new(social_history_section)
        result_hash[:resources] = @social_history
        result_hash[:patient] = resp['patient']['patient']
        result_hash[:provider] = resp['provider']
        result_hash[:contact] = resp['contact']
        result_hash[:business_entity] = resp['business_entity']['business_entity']

        if options[:summary] == "count" || options[:resource_counts] == "true"
          result_hash[:count_summary] =  result_hash[:resources].entries.length
        end
      else
        @blood_pressure_observation = BloodPressureObservation.new(resp['observations']) if resp['observations'].select{|a| a['code'] == ObservationCode::SYSTOLIC}.present?
        @pulse_oximetry_observation = PulseOximetryObservation.new(resp['observations']) if resp['observations'].select{|a| a['code'] == ObservationCode::OXYGEN_SATURATION}.present?

        @observation_entries = resp['observations'].reject{|a| [ObservationCode::SYSTOLIC,ObservationCode::DIASTOLIC,ObservationCode::OXYGEN_SATURATION,ObservationCode::INHALED_OXYGEN_CONCENTRATION].include? a['code']}
        @observation_entries << @blood_pressure_observation if @blood_pressure_observation.present?
        @observation_entries << @pulse_oximetry_observation if @pulse_oximetry_observation.present?
        @observation_type = ObservationType::VITAL_SIGNS
        result_hash[:resources] = @observation_entries
        result_hash[:blood_pressure_observation] = @blood_pressure_observation
        result_hash[:pulse_oximetry_observation] = @pulse_oximetry_observation
        result_hash[:observation_type] = @observation_type
        if options[:summary] == "count" || options[:resource_counts] == "true"
          result_hash[:count_summary] =  result_hash[:resources].entries.length
        end
      end

		else
	  end
    result_hash
	end

	def get_base_path(type,patient_id,opts)
		case type
		when 'Goal'
			"patient_summary/generate_json_by_patient_id_and_component.json"
		when 'Smoking Status'
			"patient_summary/generate_json_by_patient_id_and_component.json"
		when "Immunization"
			"patients/#{patient_id}/immunizations.json"
		when "Encounter"
			"patients/#{patient_id}/encounters.json"
		when "Condition"
			"patients/#{patient_id}/problems.json"
		when "CarePlan"
			"patient_summary/generate_json_by_patient_id_and_component.json"
    when "CareTeam"
      "businesses/#{current_business_entity}/patients/#{patient_id}/care_team_members.json"
    when 'AllergyIntolerance'
      "patient_allergies/list_by_patient.json"
    when 'Patient'
      "patients/search/v2.json"
    when 'DocumentReference'
      "patients/#{patient_id}/documents/list_by_patient_id.json"
    when 'MedicationRequest'
      "patients/#{patient_id}/medications_list.json"
    when 'Medication'
      "patients/#{patient_id}/medications_list.json"
    when 'Procedure'
      "procedure_tests/list_by_patient.json"
    when 'DiagnosticReport'
      "patient_summary/generate_json_by_patient_id_and_component.json"
    when 'Device'
      "implantable_devices/list_by_patient.json"
    when "Observation"
      get_observations_path(opts[:code])
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