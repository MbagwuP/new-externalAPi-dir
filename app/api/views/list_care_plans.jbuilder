json.care_plan_entries @plan_of_treatment.entries do |care_plan|
  json.partial! :care_plan, care_plan: care_plan
end

json.patient do
  json.partial! :patient, patient: OpenStruct.new(@patient)
end

json.business_entity do
  json.partial! :business_entity, business_entity: OpenStruct.new(@business_entity)
end
