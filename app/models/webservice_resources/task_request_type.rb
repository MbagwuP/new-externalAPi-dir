module WebserviceResources
  class TaskRequestType
    extend Client::Webservices
      
    def self.values
      cache_key = "task-request-types"
      cache_retrieval(cache_key, :list_all)
    end
  
    def self.list_all
      url = webservices_uri "task_request_types.json", "external_request=true"
      types = fetch_list(url)
      format_list_for_converter(types)
    end
    
    def self.format_list_for_converter(types)
      types_assembly = {}
      types.each do |ty|
        type_assembly = {}
        type_assembly['values'] = [ty['task_request_type']['code'], ty['task_request_type']['id'],ty['task_request_type']['name']]
        type_assembly['default'] = ty['task_request_type']['code']
        type_assembly['display'] = ty['task_request_type']['code']
        type_assembly['name'] = ty['task_request_type']['name']
        
        types_assembly[ty['task_request_type']['id']] = type_assembly
      end
      types_assembly
    end
  
  end
end