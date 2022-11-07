first_condition = OpenStruct.new(@conditions.first)
patient = OpenStruct.new(first_condition.patient)
business_entity = OpenStruct.new(first_condition.business_entity)

json.conditionEntries @conditions do |condition|
  json.condition do 
    json.partial! :condition, condition: OpenStruct.new(condition), patient: patient
  end
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end