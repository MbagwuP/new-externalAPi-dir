module Sinatra
  module V2
    module Clinical
      module Payers
        module Policies

          def self.build_url(payer_id)
            webservices_uri(Policies.path(payer_id), token: escaped_oauth_token)
          end

          def self.path(payer_id)
            "payers/#{payer_id}/policy_types"
          end

          def self.registered(app)

            app.get '/v2/payers/:payer_id/policies' do
              payer_id = params[:payer_id]
              url = Policies.build_url(payer_id)

              response = RestClient.get(url, {accept: :json})

              body(response)
              status HTTP_OK
            end
          end
        end
      end
    end
  end

  register V2::Clinical::Payers::Policies
end