module Sinatra
  module V2
    module Allergens
      def self.path
        "allergens"
      end

      def self.registered(app)

        app.get '/v2/allergens' do
          search_criteria = params[:query]
          url = webservices_uri(Allergens.path)

          response = RestClient.get(url, {params: {search: search_criteria, token: escaped_oauth_token}, accept: :json})

          body(response)
          status HTTP_OK
        end
      end
    end
  end

  register V2::Allergens
end
