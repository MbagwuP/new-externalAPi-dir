module Sinatra
  module V2
    module Practices
      module FeatureSubscription
        def self.registered(app)
          app.get '/v2/practices/:practice_id/feature-subscriptions' do

            uri = webservices_uri "businesses/#{params[:practice_id]}/subscriptions.json", token: escaped_oauth_token

            response = rescue_service_call 'List practice subscriptions' do
              RestClient.get(uri)
            end

            body(response)
            status HTTP_OK
          end


          app.post '/v2/practices/:practice_id/feature-subscriptions' do
            uri = webservices_uri "businesses/#{params[:practice_id]}/subscriptions.json", token: escaped_oauth_token

            response = rescue_service_call 'Add new practice subscription' do
              RestClient.post(uri, { plan_code: params[:plan_code], feature_code: params[:feature_code] })
            end

            body(response)
            status HTTP_OK
          end
        end
      end
    end
  end
  register V2::Practices::FeatureSubscription
end
