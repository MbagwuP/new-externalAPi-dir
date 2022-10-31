json.ObservationEntries @social_history.entries do |smoking_status|
  json.partial! :observation_smoking_status, smoking_status: smoking_status, social_history_code: @social_history.code, patient: OpenStruct.new(@patient), business_entity: OpenStruct.new(@business_entity), provider: OpenStruct.new(@provider), contact: OpenStruct.new(@contact)
end