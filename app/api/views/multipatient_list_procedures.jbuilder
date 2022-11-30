
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.procedureEntries response[:resources] do |procedure|
      json.partial! :procedure, procedure: OpenStruct.new(procedure)
    end
  end

