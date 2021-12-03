provider = OpenStruct.new(vital_sign.provider)

json.id vital_sign.id
json.text vital_sign.name
json.status vital_sign.status
json.effective_start_date vital_sign.started_at
json.effective_end_date vital_sign.ended_at

json.value vital_sign.value
json.value_unit vital_sign.value_uom
json.value_system UNIT_OF_MEASURE_CODE_SYSTEM
json.value_code vital_sign.value_abbrevitation
json.data_absent_reason_code nil

json.code vital_sign.observation_code
json.code_system LIONIC_CODE_SYSTEM
json.code_display vital_sign.name

json.provider do
  json.partial! :provider, provider: provider
end