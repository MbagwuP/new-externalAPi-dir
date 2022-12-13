
 json.resource_count @responses.count
 json.array! @responses  do |response|
    json.ObservationEntries response[:resources].entries do |smoking_status|
      json.partial! :observation_smoking_status,
                    smoking_status: smoking_status,
                    social_history_code: response[:resources].code,
                    patient: OpenStruct.new(response[:patient]),
                    business_entity: OpenStruct.new(response[:business_entity]),
                    provider: OpenStruct.new(response[:provider]),
                    contact: OpenStruct.new(response[:contact]),
                    include_provenance_target: @include_provenance_target
    end
  end

