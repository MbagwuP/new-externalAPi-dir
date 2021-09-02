patient = OpenStruct.new(condition.patient)
business_entity = OpenStruct.new(condition.business_entity)
provider = OpenStruct.new(condition.provider)

json.id condition.id
json.clinical_status condition.status
json.verification_status nil
json.category_code "encounter-diagnosis"

json.onset condition.onset_date
json.date_recorded condition.created_at

json.code condition.snomed_code
json.code_system "snomed"
json.code_display condition.problem

json.severity_code nil
json.severity_code_display nil

json.patient do
  json.partial! :patient, patient: patient
end

json.provider do
  json.partial! :provider, provider: provider
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end
