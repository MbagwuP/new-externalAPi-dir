module Sinatra
  module V2
    module Clinical
      module Payers
        module Plans

          def self.path(payer_id)
            "payers/#{payer_id}/plans"
          end

          def self.registered(app)

            app.get '/v2/payers/:payer_id/plans' do
              payer_id = params[:payer_id]
              url = webservices_uri(Plans.path(payer_id), token: escaped_oauth_token)

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