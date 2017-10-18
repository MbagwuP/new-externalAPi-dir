json.payers @payers['payers'] do |payer|
  json.payer do 
    json.id payer['id']
    json.name payer['name']
    if payer['addresses']
      json.addresses payer['addresses'] do |address|
        json.line1 address['address']['line1']
        json.line2 address['address']['line2']
        json.line3 address['address']['line3']
        json.city address['address']['city']
        json.state address['address']['state'] || DemographicCodes::Converter.cc_id_to_code(DemographicCodes::State, address['address']['state_id'])
        json.zip address['address']['zip_code']
        json.country_name address['address']['country_name'] || DemographicCodes::Converter.cc_id_to_code(DemographicCodes::Country, address['address']['country_id'])
      end
    end
    if payer['phones']
      json.phones payer['phones'] do |phone|
        json.phone_number phone['phone']['phone_number']
        json.phone_type DemographicCodes::Converter.cc_id_to_code(DemographicCodes::PhoneType, phone['phone']['phone_type_id'])
        json.phone_ext phone['phone']['phone_ext'] || phone['phone']['extension']
      end
    end
    if payer['plans']
      json.plans payer['plans'] do |plan|
        json.id plan['payer_plan']['id']
        json.name plan['payer_plan']['name']
      end
    end
  end
end