patient = OpenStruct.new(medication.patient)
provider = OpenStruct.new(medication.provider)
encounter = OpenStruct.new(medication.encounter)
patient_reported = medication.patient_reported
dosage_instructions = [
  {
    text: medication.prescription_instructions,
    date_start: medication.effective_from,
    date_end: medication.effective_to
  }
]

json.id medication.id
json.status medication.status
json.intent intent(patient_reported)
json.reported patient_reported
json.reported_reference reported_reference(patient_reported)
json.date_authored medication.created_at
json.code_system 'ndc'
json.code medication.ndc_code
json.code_display medication.drug_name

json.encounter do
  json.partial! :encounter, encounter: encounter
end

json.requester do
  if patient_reported
    json.id patient.external_id
    json.description patient.full_name
  else
    json.id provider.id
    json.description provider.name
  end
end

json.dosage_instruction dosage_instructions do |dosage_instruction|
  json.text dosage_instruction[:text]
  json.date_start dosage_instruction[:date_start]
  json.date_end dosage_instruction[:date_end]
end

json.dispense_request do
  if patient_reported
    json.partial! :dispense_request, dispense_request: nil
  else
    json.partial! :dispense_request, dispense_request: OpenStruct.new({
      refills: medication.refill_count,
      quantity_value: medication.quantity,
      quantity_unit: medication.quantity_uom,
      quantity_code: medication.quantity_uom_code,
      quantity_code_system: 'ncpdp',
      duration_value: medication.duration,
      duration_unit: medication.duration_uom,
      duration_code: medication.duration_uom_code,
      duration_code_system: 'https://ucum.org/trac'
    })
  end
end

json.provider do
  json.partial! :provider, provider: provider
end
