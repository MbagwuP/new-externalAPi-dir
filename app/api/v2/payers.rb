module Sinatra
  module V2
    module Clinical
      module Payers
        module Helpers
          def build_url()
            webservices_uri(path, token: escaped_oauth_token)
          end

          def path()
            "payers"
          end
        end

        def self.registered(app)
          app.helpers Payers::Helpers

          app.get '/v2/payers' do
            search_criteria = params[:query]
            url = build_url

            response = RestClient.get(url, {params: {search: search_criteria}, accept: :json})

            body(response)
            status HTTP_OK
          end
        end
      end
    end
  end

  register V2::Clinical::Payers
end
