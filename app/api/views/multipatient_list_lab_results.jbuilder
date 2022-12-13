json.resource_count @responses.count
  json.array! @responses  do |response|
    json.ObservationEntries response[:resources] do |result|
      json.partial! :lab_result, lab_result: OpenStruct.new(result)
    end
  end

