json.procedureEntries @responses do |procedure|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.partial! :procedure, procedure: OpenStruct.new(procedure)
end


