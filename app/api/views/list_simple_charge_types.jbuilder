json.simple_charge_types @resp do |simple_charge_type|
  json.partial! :simple_charge_type, simple_charge_type: simple_charge_type['simple_charge_type']
end
