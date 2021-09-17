provider = OpenStruct.new(procedure.provider)

json.id procedure.id

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
