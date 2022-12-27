condition = OpenStruct.new(@condition)
patient = OpenStruct.new(condition.patient)
business_entity = OpenStruct.new(condition.business_entity)

json.condition do
  json.partial! :condition, condition: condition, patient: patient, account_number: patient.external_id
  
  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
