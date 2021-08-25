medication = OpenStruct.new(@medication)
patient = OpenStruct.new(medication.patient)
business_entity = OpenStruct.new(medication.business_entity)

json.medication do
  json.partial! :medication, medication: medication
  
  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
