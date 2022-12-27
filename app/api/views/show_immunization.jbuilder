immunization = OpenStruct.new(@immunization)
patient = OpenStruct.new(immunization.patient)
provider = OpenStruct.new(immunization.provider)
business_entity = OpenStruct.new(immunization.business_entity)

json.immunization do

  status_reason = status_reason_from_reason_string(immunization.treatment_refusal_reason_text)
  json.account_number patient.external_id
  json.mrn patient.chart_number
  json.patient_name patient.full_name
  json.identifier immunization.id
  json.status immunization.status
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
  if immunization.status == 'completed'
    json.primary_source false
  else
    json.primary_source true
  end

  json.provider do
    json.identifier provider.try(:id)	
	  json.npi provider.try(:npi)
	  json.last_name provider.try(:last_name)
	  json.first_name provider.try(:first_name)
  end

  json.healthcare_entity do
	  json.partial! :healthcare_entity, healthcare_entity: business_entity
  end
end
