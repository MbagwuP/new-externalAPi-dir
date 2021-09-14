immunization = OpenStruct.new(@immunization)
patient = OpenStruct.new(immunization.patient)
business_entity = OpenStruct.new(immunization.business_entity)

json.immunization do
  json.partial! :immunization, immunization: immunization
  
  json.patient do
    json.partial! :patient, patient: patient
  end

  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
