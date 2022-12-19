json.array! @parsed do |txn|
  json.first_name txn['referral_provider']['first_name']
  json.last_name txn['referral_provider']['last_name']
  json.tax_id txn['referral_provider']['tax_id']
  json.npi txn['referral_provider']['npi']
  json.referral_source_type_id txn['referral_provider']['referral_source_type_id']

  json.addresses txn['address'] do |address|
    json.line1 txn['address']['address']['line1']
    json.line2 txn['address']['address']['line2']
    json.line3 txn['address']['address']['line3']
    json.city txn['address']['address']['city']
    json.state txn['address']['address']['state'] || WebserviceResources::Converter.cc_id_to_code(WebserviceResources::State, txn['address']['address']['state_id'])
    json.zip txn['address']['address']['zip_code']
  end

  json.phones txn['phone'] do |phone|
    json.phone_number txn['phone']['phone']['phone_number']
    json.phone_type WebserviceResources::Converter.cc_id_to_code(WebserviceResources::PhoneType, txn['phone']['phone']['phone_type_id'])
    json.phone_ext txn['phone']['phone']['phone_ext'] || txn['phone']['phone']['extension']
  end
 
end
