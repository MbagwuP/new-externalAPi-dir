allergy_reactions = OpenStruct.new(allergy.allergy_reactions.try(:first))

json.allergyIntolerance do
	json.account_number patient.external_id
	json.mrn patient.chart_number
	json.patient_name patient.full_name
	json.identifier allergy.id
	json.clinical_status allergy.status
	json.verification_status 'confirmed'
	json.type 'allergy'
	json.category allergy.allergen_class
	json.criticality allergy_reactions.try(:severity)
	json.onset allergy.onset_date
	json.date_recorded allergy.created_at
	json.code allergy.snomed_code
	json.code_system SNOMED_CODE_SYSTEM
	json.code_display allergy.allergen_type_name
	json.reaction_code allergy_reactions.try(:id)
	json.reaction_code_display allergy_reactions.try(:reaction)
	json.reaction_severity allergy_reactions.try(:severity)

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
	json.partial! :_provenance, patient: patient, record: allergy,
		provider: provider, business_entity: business_entity,
		obj: 'AllergyIntolerance'
end