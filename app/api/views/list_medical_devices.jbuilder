first_medical_device = OpenStruct.new(@medical_devices.first)
patient = OpenStruct.new(first_medical_device.patient)

json.device_entries @medical_devices do |medical_device|
  json.partial! :medical_device, medical_device: OpenStruct.new(medical_device)
end

json.patient do
  json.partial! :patient, patient: patient
end
