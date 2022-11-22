specialty = OpenStruct.new(@practicioner.specialty)
business_entity = OpenStruct.new(@practicioner.business_entity)
address = (@practicioner.addresses).first
phones = @practicioner.phones

json.practicioner do
  json.identifier @practicioner.id 
  json.first_name @practicioner.first_name
  json.last_name @practicioner.last_name
  json.middle_name @practicioner.middle_initial
  json.prefix @practicioner.prefix
  json.suffix @practicioner.suffix
  json.npi @practicioner.npi
  json.gender @practicioner.gender_name

  json.code do
    json.code ""
    json.code_system ""
  end
  json.specialty do
    json.code specialty.code
    json.code_system ""
    json.code_display specialty.name
  end

  json.phone do
    json.home get_phone_number(phones, "phone_type_code", "H")
    json.work get_phone_number(phones, "phone_type_code", "W")
    json.cellphone get_phone_number(phones, "phone_type_code", "C")
    json.main get_phone_number(phones, "phone_type_code", "M")
    json.business get_phone_number(phones, "phone_type_code", "B")
    json.fax get_phone_number(phones, "phone_type_code", "F")
  end

  json.address do
    json.type_address_code 'both'
    json.type_address_system 'http://hl7.org/fhir/ValueSet/address-type'
    json.type_address_display 'Postal & Physical'

    json.line1 address['line1']
    json.line2 address['line2']
    json.state_code address['state_code']
    json.city address['city']
    json.zip address['zip_code']
    json.country_name address['country_name']
  end

  json.healthcare_entity do
    json.identifier business_entity.id
    json.name business_entity.name
  end
end