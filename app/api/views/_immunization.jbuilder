provider = OpenStruct.new(immunization.provider)

json.id immunization.id
json.status immunization.status

status_reason = status_reason_from_reason_string(immunization.treatment_refusal_reason_text)

json.status_reason_code status_reason[:code]
json.status_reason_code_system status_reason[:system]
json.status_reason_code_display status_reason[:reason]

json.vaccine_code immunization.immunization_code
json.vaccine_code_system "http://hl7.org/fhir/sid/cvx"
json.vaccine_code_display immunization.name

json.vaccine_translation_code ""
json.vaccine_translation_code_system ""
json.vaccine_translation_code_display ""

json.occurrence_date immunization.admin_date
json.occurrence_string ""

json.provider do
  json.partial! :provider, provider: provider
end
