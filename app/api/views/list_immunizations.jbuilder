first_immunization = OpenStruct.new(@immunizations.first)
patient = OpenStruct.new(first_immunization.patient)
business_entity = OpenStruct.new(first_immunization.business_entity)

json.immunization_entries @immunizations do |immunization|
  json.partial! :immunization, immunization: OpenStruct.new(immunization)
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end