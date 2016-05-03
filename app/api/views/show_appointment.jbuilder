json.appointment do
  json.partial! :appointment, appointment: @resp['appointment'] 

  json.admit_diagnosis_id @resp['appointment']['admit_diagnosis_id']
  json.note_set_id @resp['appointment']['note_set_id']
  json.document_set_id @resp['appointment']['document_set_id']
  json.contrast @resp['appointment']['contrast']
  json.laterality @resp['appointment']['laterality']
  json.created_by_application @resp['appointment']['created_by_application']
  json.patient_instructions @resp['appointment']['patient_instructions']
  json.preferred_confirmation_method @resp['appointment']['preferred_confirmation_method']
end