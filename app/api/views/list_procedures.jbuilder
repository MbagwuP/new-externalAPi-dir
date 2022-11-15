first_procedure = OpenStruct.new(@procedures.first)
json.procedureEntries @procedures do |procedure|
  json.partial! :procedure, procedure: OpenStruct.new(procedure)
end
