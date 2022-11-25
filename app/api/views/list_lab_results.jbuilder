json.resource_count @count_summary unless @count_summary.nil?
json.ObservationEntries @lab_results do |result|
  json.partial! :lab_result, lab_result: OpenStruct.new(result)
end