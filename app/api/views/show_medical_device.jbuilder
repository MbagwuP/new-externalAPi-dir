medical_device = OpenStruct.new(@medical_device)
@patient = OpenStruct.new(medical_device.patient)

if @summary == 'count'
  json.resource_count 1
else
  json.device do
    json.partial! :medical_device, medical_device: medical_device
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

#json.patient do
#  json.partial! :patient, patient: @patient
#end
