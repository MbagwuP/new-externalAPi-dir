json.resource_count @responses.count
json.practitioner @responses do |practitioner|
    business_entity = OpenStruct.new(@organization)    
    first_name, last_name = practitioner['name'].split(' ')
    json.practitioner do
      json.identifier practitioner['id'] 
      json.first_name first_name
      json.last_name last_name
      json.middle_name practitioner['middle_initial']
      json.prefix practitioner['prefix']
      json.suffix practitioner['suffix']
      json.npi practitioner['npi']
      json.gender practitioner['gender_name']

      json.code do
        json.code ""
        json.code_system ""
      end
      json.specialty do
        json.code ""
        json.code_system ""
        json.code_display ""
      end

      json.phone do
        json.home ""
        json.work ""
        json.cellphone ""
        json.main ""
        json.business ""
        json.fax ""
      end

      json.address do
        json.type_address_code 'both'
        json.type_address_system 'http://hl7.org/fhir/ValueSet/address-type'
        json.type_address_display 'Postal & Physical'

        json.line1 ""
        json.line2 ""
        json.state_code ""
        json.city ""
        json.zip ""
        json.country_name ""
      end

      json.healthcare_entity do
        json.identifier business_entity['id']
        json.name business_entity['name']
      end
    end
end
