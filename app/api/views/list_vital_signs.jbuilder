first_vital_sign = OpenStruct.new(@vital_signs.first)
patient = OpenStruct.new(first_vital_sign.patient)
business_entity = OpenStruct.new(first_vital_sign.business_entity)

json.vital_sign_entries @vital_signs do |vital_sign|
  json.partial! :vital_sign, vital_sign: OpenStruct.new(vital_sign)
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end