json.appointment do
  json.partial! :appointment, appointment: appointment 

  json.admit_diagnosis_id appointment['admit_diagnosis_id']
  json.note_set_id appointment['note_set_id']
  json.document_set_id appointment['document_set_id']
  json.contrast appointment['contrast']
  json.laterality appointment['laterality']
  json.created_by_application appointment['created_by_application']
  json.patient_instructions appointment['patient_instructions']
  json.preferred_confirmation_method appointment['preferred_confirmation_method']
  json.encounter_id appointment['encounter_id']
end