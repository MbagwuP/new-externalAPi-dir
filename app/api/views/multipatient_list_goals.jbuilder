json.resource_count @responses.count
json.goalEntries @responses do |response|
    json.partial! :goal, goal: response[:goal], 
    patient: OpenStruct.new(response[:patient]), 
    business_entity: OpenStruct.new(response[:business_entity]), 
    provider: OpenStruct.new(response[:provider]), 
    contact: OpenStruct.new(response[:contact]), 
    include_provenance_target: @include_provenance_target
end

