module Sinatra
  module V2
    module AllergenTypes

      def self.registered(app)

        app.get '/v2/allergen_types' do

          response = FDBClient::DrugAllergy::InteroperableTypeClassification.all

          body(response.to_json)
          status HTTP_OK
        end
      end
    end
  end

  register V2::AllergenTypes
end
