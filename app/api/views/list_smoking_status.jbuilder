json.smoking_status_entries @social_history.entries do |smoking_status|
  json.partial! :smoking_status, smoking_status: smoking_status, social_history_code: @social_history.code
end

json.patient do
  json.partial! :patient, patient: OpenStruct.new(@patient)
end

json.business_entity do
  json.partial! :business_entity, business_entity: OpenStruct.new(@business_entity)
end
