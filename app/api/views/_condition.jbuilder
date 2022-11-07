json.partial! :patient, patient: patient
json.identifier condition.id

json.clinical_status condition.condition
json.verification_status condition.status
json.categoryCode "encounter-diagnosis"

json.onset condition.onset_date
json.date_recorded condition.created_at

json.code condition.snomed_code
json.code_system SNOMED_CODE_SYSTEM
json.code_display condition.problem

json.severity_code nil
json.severity_code_display nil

json.provider do
  json.partial! :provider, provider: OpenStruct.new(condition.provider)
end
json.healthcare_entity do
	json.partial! :healthcare_entity, healthcare_entity: condition.business_entity
end
