json.resource_count @responses.count
json.procedureEntries @responses do |procedure|
    json.partial! :procedure, procedure: OpenStruct.new(procedure)
end


