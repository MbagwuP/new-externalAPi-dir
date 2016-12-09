module Sinatra
  module V2
    module Drugs
      def self.registered(app)
        app.get '/v2/drugs/search' do
          query     = { token: escaped_oauth_token, search: params[:search] }
          uri       = webservices_uri("drugs/search.json", query)

          response  = rescue_service_call 'Drugs Rx Lookup' do 
            RestClient.get(uri)
          end

          body(response)
          status HTTP_OK
        end
      end
    end
  end
  register V2::Drugs
end
