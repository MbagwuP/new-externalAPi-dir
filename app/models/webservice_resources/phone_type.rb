module WebserviceResources
  class PhoneType < WebserviceClient
    def self.values
      cache_key = "phone-types"
      return cache_retrieval(cache_key, :phone_types_from_webservices)
    end

    def self.phone_types_from_webservices
      phone_types = make_service_call 'Phone Type Look Up' do
        RestClient.get(webservices_uri "people/list_all_phone_types.json", :api_key => ApiService::APP_API_KEY)
      end
      phone_types = JSON.parse phone_types
      type_assembly = {}
      phone_types.each do |phone_type|
        phone_type['phone_type']['code'] = '' unless phone_type['phone_type']['code'].present?
        type_assembly[phone_type['phone_type']['id']] = { 'values'  => [phone_type['phone_type']['code'], phone_type['phone_type']['id']],
                                                          'default' => phone_type['phone_type']['code'],
                                                          'display' => phone_type['phone_type']['name'] }
      end
      type_assembly
    end
  end
end