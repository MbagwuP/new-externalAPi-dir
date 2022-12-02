json.account_number account_number.nil? ? patient.id : account_number
json.mrn patient.chart_number
json.patient_name patient.full_name
json.identifier condition.id
json.id condition.id
json.clinical_status condition.active == "yes" ? "active" : "inactive"
json.verification_status "unconfirmed"
json.category_code "encounter-diagnosis"
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
	json.partial! :healthcare_entity, healthcare_entity: OpenStruct.new(condition.business_entity)
end
