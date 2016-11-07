module Sinatra
  module V2
    module Clinical
      module Payers
        module Plans
          module Helpers

            def build_url(payer_id)
              webservices_uri(path(payer_id), token: escaped_oauth_token)
            end

            def path(payer_id)
              "payers/#{payer_id}/plans"
            end
          end

          def self.registered(app)
            app.helpers Plans::Helpers

            app.get '/v2/payers/:payer_id/plans' do
              payer_id = params[:payer_id]
              url = build_url(payer_id)

              response = RestClient.get(url, {accept: :json})

              body(response)
              status HTTP_OK
            end
          end
        end
      end
    end
  end
  register V2::Clinical::Payers::Plans
end