module Sinatra
  module V2
    module Allergens
      def self.path
        "allergens"
      end

      def self.registered(app)

        app.get '/v2/allergens' do
          search_criteria = params[:query]
          allergen_type = params[:allergen_type_code]
          url = webservices_uri(Allergens.path)

          response = ApiService::ENABLE_FDB ? Allergens.fdb_search(search_criteria, allergen_type) : Allergens.lexi_search(url, search_criteria, escaped_oauth_token)

          body(response)
          status HTTP_OK
        end
      end

      def self.lexi_search(url, search_criteria, token)
        RestClient.get(url, {params: {search: search_criteria, token: token}, accept: :json})
      end

      def self.fdb_search(search_criteria, allergen_type_code)
        response = FDBClient::DrugAllergy::InteroperableAllergen.search(search_criteria, allergen_type_code)
        response.to_json
      end
    end
  end

  register V2::Allergens
end
