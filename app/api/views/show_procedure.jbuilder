procedure = OpenStruct.new(@procedure)
patient = OpenStruct.new(procedure.patient)
business_entity = OpenStruct.new(procedure.business_entity)

json.procedure do
  json.partial! :procedure, procedure: OpenStruct.new(@procedure)
  
  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end