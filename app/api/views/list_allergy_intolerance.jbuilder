first_allergy = OpenStruct.new(@allergies.first)
patient = OpenStruct.new(first_allergy.patient)
business_entity = OpenStruct.new(first_allergy.business_entity)

json.allergy_intolerance_entries @allergies do |allergy|
  json.partial! :allergy, allergy: OpenStruct.new(allergy)
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end
