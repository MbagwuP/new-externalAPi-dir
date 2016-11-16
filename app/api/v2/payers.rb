module Sinatra
  module V2
    module Clinical
      module Payers
        def self.path()
          "payers"
        end

        def self.registered(app)

          app.get '/v2/payers' do
            search_criteria = params[:query]
            url = webservices_uri(Payers.path)

            response = RestClient.get(url, {params: {search: search_criteria, token: escaped_oauth_token}, accept: :json})

            body(response)
            status HTTP_OK
          end
        end
      end
    end
  end

  register V2::Clinical::Payers
end
