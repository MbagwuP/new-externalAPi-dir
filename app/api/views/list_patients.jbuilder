json.resource_count @count_summary unless @count_summary.nil?
json.patientEntries @patients do |patient|
  json.partial! :patient_details, 
  patient: OpenStruct.new(patient["patient"]), 
  include_provenance_target: @include_provenance_target
end