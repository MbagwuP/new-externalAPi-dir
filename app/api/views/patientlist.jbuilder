json.patientListEntries @patients do |patient|
  json.partial! :patient_entry, patient: OpenStruct.new(patient["patient"])
end