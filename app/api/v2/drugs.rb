module Sinatra
  module V2
    module Drugs
      def self.registered(app)
        app.get '/v2/drugs/search' do
          results = FDBClient::CoreDrug::DispensableDrug.search(params[:search])
          drugs = results.items.map{ |x| FDBClient::CoreDrug::LiteDispensableDrug.new(x) if x.has_packaged_drugs}.compact.to_json

          body(drugs)
          status HTTP_OK
        end
      end
    end
  end
  register V2::Drugs
end
