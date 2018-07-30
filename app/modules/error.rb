module Error
  
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
