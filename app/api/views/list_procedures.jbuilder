first_procedure = OpenStruct.new(@procedures.first)

json.resource_count @count_summary unless @count_summary.nil?
json.procedureEntries @procedures do |procedure|
  json.partial! :procedure, procedure: OpenStruct.new(procedure)
end
