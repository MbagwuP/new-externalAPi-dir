module Client
  module Webservices

    def make_request(description,method,url,payload=nil)
      response = rescue_service_call(description,true) do 
        case method 
          when "post" 
            RestClient.post(url, payload, {:api_key => ApiService::APP_API_KEY, :accept => :json} )
          when "get"
            RestClient.get(url, { :api_key => ApiService::APP_API_KEY, :accept => :json })
          when "put"
            RestClient.put(url, payload, {:api_key => ApiService::APP_API_KEY, :accept => :json})
          else 
            raise StandardError, "Invalid Request Method"
        end
      end
      JSON.parse(response)
    end 
    
    def rescue_service_call(call_description, expose_ws_error=false)
      begin
        yield
      rescue => e
          error_detail = if expose_ws_error
                           ws_error = JSON.parse(e.http_body)['error']['message'] rescue nil
                           ws_error || e.message
                         else
                           e.message
                         end
          error_msg = "#{call_description} Failed - #{error_detail}"
       raise Error::Error.new(e.http_code,error_msg)
      end
    end                       
    
    def webservices_uri(path, query_params=nil)
      uri = URI.parse(ApiService::API_SVC_URL + path)
      uri.query = query_params.is_a?(Hash) ? query_params.to_query : query_params
      uri.to_s
    end
    
    def fetch_list(url)
      request = RestClient::Request.new(:url => url, :method => :get)
      signed_request = CCAuth::InternalService::Request.sign!(request)
      raw_response = signed_request.execute
      JSON.parse(raw_response)
    end

    def get_fhir_codes
      return @fhir if defined?(@fhir)
      @fhir = YAML.load(File.open(Dir.pwd + '/config/fhir.yml'))
    end

    def cache_retrieval(cache_key, webservices_method)
       codes = nil
       begin
        codes = XAPI::Cache.fetch(cache_key, 54000) do
          self.send(webservices_method)
        end
      rescue Dalli::DalliError
        LOG.warn("cannot reach cache store")
        codes = self.send(webservices_method)
      rescue CCAuth::Error::ResponseError => e
        return e
      end
      return codes
    end


  end
end