first_procedure = OpenStruct.new(@procedures.first)
patient = OpenStruct.new(first_procedure.patient)
business_entity = OpenStruct.new(first_procedure.business_entity)

json.procedure_entries @procedures do |procedure|
  json.partial! :procedure, procedure: OpenStruct.new(procedure)
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end