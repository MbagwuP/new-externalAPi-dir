json.goalEntriesList do
  json.array! @responses do |response|
    json.goalEntries response[:resources].entries do |goal|
      json.partial! :goal, goal: goal, patient: OpenStruct.new(response[:patient]), business_entity: OpenStruct.new(response[:business_entity]), provider: OpenStruct.new(response[:provider]), contact: OpenStruct.new(response[:contact]), include_provenance_target: @include_provenance_target
    end
  end
end
