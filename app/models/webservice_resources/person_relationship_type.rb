module WebserviceResources
  class PersonRelationshipType
    extend Client::Webservices
      
    def self.values
      cache_key = "person-relationship-types"
      cache_retrieval(cache_key, :list_all)
    end
  
    def self.list_all
      url = webservices_uri "person_relationship_types/list_all.json"
      types = fetch_list(url)
      format_list_for_converter(types)
    end
    
    def self.format_list_for_converter(types)
      types_assembly = {}
      types.each do |ty|
        type_assembly = {}
        type_assembly['values'] = [ty['person_relationship_type']['name'].underscore.gsub(' ', '_'), ty['person_relationship_type']['id']]
        type_assembly['default'] = ty['person_relationship_type']['code']
        type_assembly['display'] = ty['person_relationship_type']['code']
        types_assembly[ty['person_relationship_type']['id']] = type_assembly
      end
      types_assembly
    end
  end
end