json.immunizationEntriesList do
  json.array! @responses  do |immunizations|
    json.immunizationEntries immunizations do |immunization|
      immunizationItem = OpenStruct.new(immunization)
      json.partial! :immunization, immunization: immunizationItem,
                    patient: OpenStruct.new(immunizationItem.patient),
                    business_entity: OpenStruct.new(immunizationItem.business_entity),
                    provider: OpenStruct.new(immunizationItem.provider),
                    include_provenance_target: @include_provenance_target
    end
  end
end
