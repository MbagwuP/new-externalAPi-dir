module Sinatra
  module Example
   
    # called immediately after the extension module is added to the Sinatra::Base subclass 
    # and is passed the class that the module was registered with
    def self.registered(app)
    	
      app.get '/example' do
        "Hello World"
      end

    end

  end
  register Example
end