vital_sign = OpenStruct.new(@vital_sign)
patient = OpenStruct.new(vital_sign.patient)
business_entity = OpenStruct.new(vital_sign.business_entity)

json.vital_sign do
  json.partial! :vital_sign, vital_sign: OpenStruct.new(vital_sign)
  
  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end