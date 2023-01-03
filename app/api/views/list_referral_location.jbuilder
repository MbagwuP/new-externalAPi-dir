json.array! @resp do |txn|
  json.location_id txn['id']
  json.location_name txn['location_name']
  json.addresses txn['address'] do |address|
    json.line1 txn['address']['address']['line1']
    json.line2 txn['address']['address']['line2']
    json.line3 txn['address']['address']['line3']
    json.city txn['address']['address']['city']
    json.state txn['address']['address']['state'] || WebserviceResources::Converter.cc_id_to_code(WebserviceResources::State, txn['address']['address']['state_id'])
    json.zip txn['address']['address']['zip_code']
  end

  json.phones txn['phones'] do |phone|
    json.phone_number phone['phone_number']
    json.phone_type_code phone['phone_type_code']
    json.extension phone['phone_ext']
  end
  
end
