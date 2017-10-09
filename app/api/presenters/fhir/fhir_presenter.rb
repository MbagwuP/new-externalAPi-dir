module Fhir
  class FhirPresenter
      def generate_telecom(phones, email)
      telecom = []
      phones ||= []
      phones.each do |phone|
        #FIX ME: FAXES?
        resource = {}
        resource['system'] = 'phone'
        resource['value'] = phone['phone_number']
        resource['use'] = 'FIX ME: ' + phone['phone_type'].to_s
        telecom << resource
      end
      telecom << {system: 'email', value: email, use: 'home'} if email.present?
      telecom
    end

    def generate_name(first_name, last_name, prefix=nil, suffix=nil)
      name = { use: 'usual',
               family: [last_name],
               given: [first_name] }

      name['suffix'] = [suffix] if suffix.present?
      name['prefix'] = [prefix] if prefix.present?
      [name]
    end

    def generate_addresses(addresses, use)
      addrs = []
      addresses.each do |address|
        resource = {}
        resource['use'] = use
        resource['text'] = address['line1'] + ' ' + (address['line2'] || '') + ' ' + address['city'] + ', ' + address['state'] + ' ' + (address['country_name'] || '')
        resource['line'] = [address['line1']]
        resource['line'] << address['line2'] if address['line2'].present?
        resource['city'] = address['city']
        resource['state'] = WebserviceResources::Converter.cc_id_to_code(WebserviceResources::State, address['state_id'])
        resource['postalCode'] = address['zip'] || address['zip_code']
        resource['country'] = (address['country_name'] || '')
        addrs << resource
      end
      addrs
    end

    def generate_marital_status(marital_status_code)
      display = WebserviceResources::Converter.display_by_code(WebserviceResources::MaritalStatus, marital_status_code)
      marital_status = {coding: Array.new}
      marital_status[:coding] << {system: 'http://hl7.org/fhir/v3/MaritalStatus', code: marital_status_code, display: display}
      marital_status
    end

    def generate_photo(photo)
      photo = RestClient.get(photo['medium'])
      resource = {}
      file = Tempfile.new('photo')
      file.write(photo)
      resource['contentType'] = "#{`file --mime -b #{file.path}`}".split.first.chop
      resource['data'] = Base64.encode64(photo)
      [resource]
    end

    def generate_communication(language_id)
      #FIX ME: Should actually be a ISO6391 code. . .
      lang = WebserviceResources::Converter.cc_id_to_code(WebserviceResources::Language, language_id)
      disp = WebserviceResources::Converter.display_by_code(WebserviceResources::Language, lang)
      coding = { system: 'urn:ietf:rfc:6392',
                 code: lang,
                 display: disp }

      resource = { preferred: true,
                   language: coding }

      [resource]
    end
  end
end