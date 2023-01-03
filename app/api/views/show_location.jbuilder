location = OpenStruct.new(@location)
address = OpenStruct.new(location["address"])
phones = location.phones
business_entity = OpenStruct.new(@business_entity)

json.location do
  json.identifier location.id
  json.status "active"
  json.name location.name
  
  json.phone do
    json.home get_phone_number(phones, "phone_type", "Home")
    json.work get_phone_number(phones, "phone_type", "Work") 
    json.cellphone get_phone_number(phones, "phone_type", "Cellphone")
    json.main  get_phone_number(phones, "phone_type", "Main")
    json.business get_phone_number(phones, "phone_type", "Business")
    json.fax get_phone_number(phones, "phone_type", "Fax")
  end

  json.address do
    json.line1 address.line1
    json.line2 address.line2
    json.state_code address.state_code
    json.city address.city
    json.zip address.zip_code
    json.country_name address.country_name
  end

  json.managingOrganization do
    json.identifier business_entity.id
    json.name business_entity.name
  end
end
