if defined?(dispense_request) && dispense_request.nil?
  json.nil!
else
  json.refills dispense_request.refills
  json.quantity_value dispense_request.quantity_value
  json.quantity_unit dispense_request.quantity_unit
  json.quantity_code dispense_request.quantity_code
  json.quantity_code_system dispense_request.quantity_code_system
  json.duration_value dispense_request.duration_value
  json.duration_unit dispense_request.duration_unit
  json.duration_code dispense_request.duration_code
  json.duration_code_system dispense_request.duration_code_system
end