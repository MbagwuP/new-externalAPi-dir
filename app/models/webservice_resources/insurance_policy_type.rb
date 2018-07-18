module WebserviceResources
  class InsurancePolicyType  
    extend Client::Webservices
    
    def self.values
      cache_key = "insurance-policy-types"
      cache_retrieval(cache_key, :list_all)
    end
  
    def self.list_all
      url = webservices_uri "insurance_policy_types/list_all.json"
      types = fetch_list(url)
      format_list_for_converter(types)
    end
    
    def self.format_list_for_converter(types)
      types_assembly = {}
      types.each do |ty|
        type_assembly = {}
        type_assembly['values'] = [ty['insurance_policy_type']['name'].underscore.gsub(' ', '_'), ty['insurance_policy_type']['id']]
        type_assembly['default'] = ty['insurance_policy_type']['code']
        type_assembly['display'] = ty['insurance_policy_type']['code']
        types_assembly[ty['insurance_policy_type']['id']] = type_assembly
      end
      types_assembly
    end
  end
end