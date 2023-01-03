provider = OpenStruct.new(procedure.provider)
patient = OpenStruct.new(procedure.patient)
business_entity = OpenStruct.new(procedure.business_entity)

json.procedure do
  json.account_number patient.external_id
  json.mrn patient.chart_number
  json.patient_name patient.full_name
  json.identifier procedure.id

  json.event_status procedure.status
  json.performed_period_start procedure.procedure_effective_from
  json.performed_period_end procedure.procedure_effective_to

  json.code procedure.code
  json.code_system CPT_CODE_SYSTEM
  json.code_display procedure.short_description
  json.code_text procedure.long_description
  json.provider do
    json.partial! :provider, provider: provider
  end
  json.healthcare_entity do
    json.identifier business_entity.id
    json.name business_entity.name
  end
  json.patient do
    json.partial! :patient, patient: patient
  end

  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end

end
if @include_provenance_target
  json.partial! :provenance, patient: patient, record: procedure, provider: provider, business_entity: business_entity, obj: 'Procedure'
end