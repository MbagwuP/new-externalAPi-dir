module WebserviceResources
  class WebserviceClient < Request 
    def self.make_service_call call_description
      begin
        yield
      rescue => e
        error_detail = JSON.parse(e.http_body)['error']['message'] rescue nil
        error_msg = "#{call_description} Failed - #{error_detail}"
      end
    end
    
    def self.fetch_list(url)
      request = RestClient::Request.new(:url => url, :method => :get)
      signed_request = CCAuth::InternalService::Request.sign!(request)
      raw_response = signed_request.execute
      JSON.parse(raw_response)
    end

    def self.get_fhir_codes
      return @fhir if defined?(@fhir)
      @fhir = YAML.load(File.open(Dir.pwd + '/config/fhir.yml'))
    end

    def self.cache_retrieval cache_key, webservices_method
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