json.goal do
	json.account_number patient.external_id
	json.mrn patient.chart_number
	json.patient_name [contact.first_name,contact.last_name].compact.join(" ")
	json.identifier goal.id
	json.text goal.title
	json.text_status "generated"
	json.life_cycle_status "proposed"
	json.achievement_status nil
	json.description goal.title
	start_date = goal.start_date ? Date.strptime(goal.start_date, '%m/%d/%Y') : nil
	target_date = goal.target_date ? Date.strptime(goal.target_date, '%m/%d/%Y') : nil
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

if include_provenance_target
	json.partial! :_provenance, patient: patient, record: goal, provider: provider, business_entity: business_entity, obj: 'Goal'
end
