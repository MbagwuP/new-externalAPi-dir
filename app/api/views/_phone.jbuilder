json.phone_number phone['phone_number']
json.phone_type DemographicCodes::Converter.cc_id_to_code(DemographicCodes::PhoneType, phone['phone_type'])
json.phone_ext phone['phone_ext'] || phone['extension']
json.is_primary phone['is_primary'] unless phone['is_primary'].nil?
