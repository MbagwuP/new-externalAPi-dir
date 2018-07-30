module WebserviceResources
  class EligibilityMethod
    extend Client::Webservices  
    
    def self.values
      cache_key = "eligibility-methods"
      cache_retrieval(cache_key, :list_all)
    end
    
    def self.list_all
      url = webservices_uri "eligibility_methods.json"
      methods = rescue_service_call 'Eligibility Method Look Up' do
        fetch_list(url)
      end
      format_list_for_converter(methods)
    end
    
    def self.format_list_for_converter(methods)
      methods_assembly = {}
      methods.each do |em|
        method_assembly = {}
        method_assembly['values'] = [em['eligibility_method']['code'], em['eligibility_method']['id']]
        method_assembly['default'] = em['eligibility_method']['code']
        method_assembly['display'] = em['eligibility_method']['code']
        methods_assembly[em['eligibility_method']['id']] = method_assembly
      end
      methods_assembly
    end

  end
end