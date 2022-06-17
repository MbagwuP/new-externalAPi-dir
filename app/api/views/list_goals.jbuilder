json.goal_entries @goal.entries do |goal|
  json.partial! :goal, goal: goal
end

json.patient do
  json.partial! :patient, patient: OpenStruct.new(@patient)
end

json.business_entity do
  json.partial! :business_entity, business_entity: OpenStruct.new(@business_entity)
end
