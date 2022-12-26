patient = OpenStruct.new(@patient)
goal = OpenStruct.new(@goal)
provider = OpenStruct.new(@provider)
business_entity = OpenStruct.new(@business_entity)
json.goal do
	json.account_number patient.external_id
	json.mrn patient.chart_number
	json.patient_name [patient.first_name,patient.last_name].compact.join(" ")
	json.identifier goal.id
	json.text goal.description
	json.text_status "generated"
	json.life_cycle_status "proposed"
	json.achievement_status nil
	json.description goal.description
	start_date = goal.effective_from ? goal.effective_from.to_date.strftime('%m-%d-%Y') : nil
	target_date = goal.effective_to ? goal.effective_to.to_date.strftime('%m-%d-%Y') : nil
	json.start_date start_date
	json.target_date target_date

	json.provider do
	  json.identifier provider.try(:id)	
		json.npi provider.try(:npi)
		json.last_name provider.try(:last_name)
		json.first_name provider.try(:first_name)
	end

	json.healthcare_entity do
		json.partial! :healthcare_entity, healthcare_entity: business_entity
	end
end
