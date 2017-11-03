class Request
  
  def self.make_request(description,method,url,payload=nil)
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
  
  def self.webservices_uri(path, query_params=nil)
    uri = URI.parse(ApiService::API_SVC_URL + path)
    uri.query = query_params.is_a?(Hash) ? query_params.to_query : query_params
    uri.to_s
  end
  
  def self.rescue_service_call(call_description, expose_ws_error=false)
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
     raise Error.new(e.http_code,error_msg)
    end
  end
  
  class Error < StandardError
    attr_accessor :http_code, :message
    def initialize(error_code, message)
      @http_code  = error_code
      @message = message
      super(@message)
    end
  end
    
  class InvalidRequestError < StandardError
    attr_accessor :http_code, :message
    def initialize(message)
      @http_code  = 400
      @message = message
      super(@message)
    end
  end
  
end 