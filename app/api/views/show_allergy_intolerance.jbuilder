allergy = OpenStruct.new(@allergy)
patient = OpenStruct.new(allergy.patient)
business_entity = OpenStruct.new(allergy.business_entity)

json.allergy_intolerance do
  json.partial! :allergy, allergy: allergy
  
  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
