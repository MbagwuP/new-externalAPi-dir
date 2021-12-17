organization = OpenStruct.new(@organization)

json.organization do |json|
  json.id organization.guid
  json.npi organization.npi
  json.active organization.status
  
  json.type 'http://terminology.hl7.org/CodeSystem/organization-type'
  json.type_display 'Healthcare Provider'
  json.type_code 'prov'
  
  json.name organization.name
  json.phones organization.phones do |phone|
    # FHIR rule: The telecom of an organization can never be of use 'home'
    next if phone['phone_type_code'] == HOME_CODE_FROM_WEBSERVICE

    json.phone_system phone['phone_type_name']
    json.value phone['phone_number']
  end

  json.address organization.addresses do |address|
    # FHIR rule: The address of an organization can never be of use 'home'
    next if address['address_type_name'] == 'Home'

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
end
