medical_device = OpenStruct.new(@medical_device)
patient = OpenStruct.new(medical_device.patient)

json.device do
  json.partial! :medical_device, medical_device: medical_device
end

json.patient do
  json.partial! :patient, patient: patient
end
