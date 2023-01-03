first_allergy = OpenStruct.new(@allergy.first)
allergy_reactions = OpenStruct.new(first_allergy.allergy_reactions.first)
patient = OpenStruct.new(first_allergy.patient)
provider = OpenStruct.new(first_allergy.provider)
business_entity = OpenStruct.new(first_allergy.business_entity)

json.allergyIntolerance do
	json.account_number patient.external_id
	json.mrn patient.chart_number
	json.patient_name patient.full_name
	json.identifier first_allergy.id
	json.clinical_status first_allergy.status
	json.verification_status 'confirmed'
	json.type 'allergy'
	json.category first_allergy.allergen_class
	json.criticality allergy_reactions.severity
	json.onset first_allergy.onset_date
	json.date_recorded first_allergy.created_at
	json.code first_allergy.snomed_code
	json.code_system SNOMED_CODE_SYSTEM
	json.code_display first_allergy.allergen_type_name
	json.reaction_code allergy_reactions.id
	json.reaction_code_display allergy_reactions.reaction
	json.reaction_severity allergy_reactions.severity

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