json.ObservationEntriesList do
  json.array! @responses  do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.ObservationEntries response[:resources] do |result|
      json.partial! :lab_result, lab_result: OpenStruct.new(result)
    end
  end
end
