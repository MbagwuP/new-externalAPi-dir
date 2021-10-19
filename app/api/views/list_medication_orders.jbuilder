first_medication = OpenStruct.new(@medications.first)
patient = OpenStruct.new(first_medication.patient)
business_entity = OpenStruct.new(first_medication.business_entity)

json.medications @medications do |medication|
  json.partial! :medication, medication: OpenStruct.new(medication)
end

json.patient do
  json.partial! :patient, patient: patient
end

json.business_entity do
  json.partial! :business_entity, business_entity: business_entity
end