specialty = OpenStruct.new(@practicioner.specialty)
business_entity = OpenStruct.new(@practicioner.business_entity)

json.practicioner do
  json.id @practicioner.id 
  json.first_name @practicioner.first_name
  json.last_name @practicioner.last_name
  json.middle_name @practicioner.middle_initial
  json.prefix @practicioner.prefix
  json.suffix @practicioner.suffix
  json.npi @practicioner.npi
  json.gender @practicioner.gender_name

  json.specialty do
    json.code specialty.code
    json.code_system
    json.code_display specialty.name
  end

  json.phones @practicioner.phones do |phone|
    # FHIR rule: The telecom of an organization can never be of use 'home'
    next if phone['phone_type_code'] == HOME_CODE_FROM_WEBSERVICE

    json.phone_system phone['phone_type_name']
    json.value phone['phone_number']
  end

  json.addresses @practicioner.addresses do |address|
    # FHIR rule: The address of an organization can never be of use 'home'
    next if address['address_type_code'] == HOME_CODE_FROM_WEBSERVICE

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

  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
