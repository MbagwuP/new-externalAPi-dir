json.phone_number phone['phone_number']
json.phone_type WebserviceResources::Converter.cc_id_to_code(WebserviceResources::PhoneType, phone['phone_type'])
json.phone_ext phone['phone_ext'] || phone['extension']
json.is_primary phone['is_primary'] unless phone['is_primary'].nil?
