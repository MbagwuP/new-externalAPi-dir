json.resource_count @responses.count 

 json.organization @responses do |response|
          organization = OpenStruct.new(response)
          addresses = organization.addresses
          phones = organization.phones
          primary_address = addresses.find {|address| address["is_primary"] == true}

          json.organization do
            json.identifier organization.id
            json.npi organization.npi
            json.active organization.status
            json.clia " "
            json.ein " "
            
            json.type 'http://terminology.hl7.org/CodeSystem/organization-type'
            json.type_display 'Healthcare Provider'
            json.type 'prov'
            json.name organization.name
            
            json.phone do
              json.home get_phone_number(phones, "phone_type_code", "H")
              json.work get_phone_number(phones, "phone_type_code", "W")
              json.cellphone get_phone_number(phones, "phone_type_code", "C")
              json.main get_phone_number(phones, "phone_type_code", "M")
              json.business get_phone_number(phones, "phone_type_code", "B")
              json.fax get_phone_number(phones, "phone_type_code", "F")
            end

            json.address do
              json.line1 primary_address['line1']
              json.line2 primary_address['line2']
              json.state_code primary_address['state_code']
              json.city primary_address['city']
              json.zip primary_address['zip_code']
              json.country_name primary_address['country_name']
            end
          end
    end

