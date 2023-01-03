json.resource_count @responses.count
json.allergyIntolerance @responses do |allergy|
      allergyItem = OpenStruct.new(allergy)
      json.partial! :allergy, allergy: allergyItem,
                    patient: OpenStruct.new(allergyItem.patient),
                    business_entity: OpenStruct.new(allergyItem.business_entity),
                    provider: OpenStruct.new(allergyItem.provider),
                    include_provenance_target: @include_provenance_target
end