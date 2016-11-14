module Fhir
  class PatientPresenter < FhirPresenter
    def initialize(patient)
      @patient = patient
    end

    def as_json
      resource = {
        resourceType: 'Patient',
        id: @patient['id'],
        text: generate_text,
        identifier: generate_external_identifier,
        name: generate_name(@patient['first_name'], @patient['last_name'], @patient['prefix'], @patient['suffix']),
        telecom: generate_telecom(@patient['phones'], @patient['email']),
        gender: (@patient['gender'] || 'unknown').downcase,
        birthDate: @patient['dob'].to_datetime.strftime('%Y-%m-%d'),
        deceasedBoolean: @patient['date_of_death'].present?,
        address: generate_addresses(@patient['addresses'], 'home'),
        maritalStatus: generate_marital_status(@patient['marital_status_code']),
        photo: generate_photo(@patient['photo']),
        communication: generate_communication(@patient['language_id']),
        careProvider: generate_care_provider_reference,
        active: @patient['status_id'] == 'A'
      }
      resource[:deceasedDateTime] = @patient['date_of_death'] if @patient['date_of_death'].present?
      resource
    end

    def generate_care_provider_reference
      resource = { reference: "/physicians/#{@patient['primary_provider_npi']}",
                   display: "NPI: #{@patient['primary_provider_npi']}"
                   }
    end

    def generate_external_identifier
      resource = [{  use: 'usual',
                     type: {
                       coding: [{
                                  system: 'http://hl7.org/fhir/v2/0203',
                                  code: 'PT'
                       }]
                     },
                     system: 'urn:oid:0.1.2.3.4.5.6.7',
                     value: @patient['id']
                     }]
    end

    def generate_text
      resource = {
        status: 'generated',
        div: "<div><p>Patient #{@patient['first_name']}  #{@patient['middle_initial']} #{@patient['last_name']} @ #{@patient['business_entity_name']} <br> PT = #{@patient['id']}</p></div>"
      }
    end

  end
end

