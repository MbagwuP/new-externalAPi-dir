first_medical_device = OpenStruct.new(@medical_devices.first)
@patient = OpenStruct.new(first_medical_device.patient) #collection of devices is for one patient

if @summary == 'count'
    json.resource_count @medical_devices.count
else
  json.deviceEntries @medical_devices do |medical_device|
    json.device do
      json.partial! :medical_device, medical_device: OpenStruct.new(medical_device)
    end
    if @include_provenance_target
      device_object = OpenStruct.new(medical_device)

      provider_object = OpenStruct.new(:id => @patient.provider_id) if @patient.try(:provider_id)
      provider_object = OpenStruct.new(:id => 0) if !provider_object

      be_object = OpenStruct.new(:id => @patient.be_id) if @patient.try(:be_id)
      be_object = OpenStruct.new(:id => 0) if !be_object

      json.partial! :provenance, patient: @patient, record: device_object, provider: provider_object, business_entity: be_object, obj: 'Device'
    end
  end
end
