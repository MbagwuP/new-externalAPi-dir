json.line1 address['line1']
json.line2 address['line2']
json.line3 address['line3']
json.city address['city']
json.state address['state'] || WebserviceResources::Converter.cc_id_to_code(WebserviceResources::State, address['state_id'])
json.zip address['zip_code']
json.county_name address['county_name']
json.country_name address['country_name'] || WebserviceResources::Converter.cc_id_to_code(WebserviceResources::Country, address['country_id'])
json.is_primary address['is_primary'] unless address['is_primary'].nil?
json.latitude address['latitude']
json.longitude address['longitude']