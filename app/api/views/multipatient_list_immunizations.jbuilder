json.resource_count @responses.count
json.immunization @responses do |immunization|
      immunizationItem = OpenStruct.new(immunization)
      json.resource_count immunization[:count_summary] unless immunization[:count_summary].nil?
      json.partial! :immunization, immunization: immunizationItem,
                    patient: OpenStruct.new(immunizationItem.patient),
                    business_entity: OpenStruct.new(immunizationItem.business_entity),
                    provider: OpenStruct.new(immunizationItem.provider),
                    include_provenance_target: @include_provenance_target

  end

