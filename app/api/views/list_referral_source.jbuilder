json.array! @parsed do |txn|
  json.full_name txn['referral_provider']['first_name'] + " " + txn['referral_provider']['last_name']
  json.first_name txn['referral_provider']['first_name']
  json.last_name txn['referral_provider']['last_name']
  json.address_1 txn['address']['address']['line1']
  json.address_2 txn['address']['address']['line2']
  json.city txn['address']['address']['city']
  json.state txn['address']['address']['state'] || WebserviceResources::Converter.cc_id_to_code(WebserviceResources::State, txn['address']['address']['state_id'])
  json.zip_code txn['address']['address']['zip_code']
  json.phone_number txn['phone']['phone']['phone_number']
  json.phone_type WebserviceResources::Converter.cc_id_to_code(WebserviceResources::PhoneType, txn['phone']['phone']['phone_type_id'])
  json.phone_ext  txn['phone']['phone']['extension']
  json.fax txn['fax']
  json.tax_id txn['referral_provider']['tax_id']
  json.npi txn['referral_provider']['npi']
  json.referral_source_type_id txn['referral_provider']['referral_source_type_id']

end
