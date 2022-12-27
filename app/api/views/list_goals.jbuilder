json.resource_count @count_summary unless @count_summary.nil?
json.goalEntries @goal.entries do |goal|
  json.partial! :goal, goal: goal, 
  patient: OpenStruct.new(@patient), 
  business_entity: OpenStruct.new(@business_entity), 
  provider: OpenStruct.new(@provider), 
  contact: OpenStruct.new(@contact), 
  include_provenance_target: @include_provenance_target
end
