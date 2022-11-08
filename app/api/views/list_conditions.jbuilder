first_condition = OpenStruct.new(@conditions.first)
patient = OpenStruct.new(first_condition.patient)
business_entity = OpenStruct.new(first_condition.business_entity)

json.condition_entries @conditions do |condition|
  json.partial! :condition, condition: OpenStruct.new(condition)
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end