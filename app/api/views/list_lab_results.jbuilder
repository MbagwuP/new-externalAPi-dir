json.resource_count @count_summary unless @count_summary.nil?
json.ObservationEntries @lab_results do |result|
  json.partial! :lab_result, lab_result: OpenStruct.new(result["lab_request_test"]), provider: OpenStruct.new(@provider), patient: OpenStruct.new(@patient),
          business_entity: OpenStruct.new(@business_entity), code: @code, include_provenance_target: @include_provenance_target
end