module Sinatra
  module V2
    module Clinical
      module Payers
        def self.path()
          "payers"
        end

        def self.registered(app)

          # app.get '/v2/payers' do
          #   search_criteria = params[:query]
          #   url = webservices_uri(Payers.path)
          #   binding.pry
          #   response = RestClient.get(url, {params: {search: search_criteria, token: escaped_oauth_token}, accept: :json})
          # 
          #   body(response)
          #   status HTTP_OK
          # end
          
          app.get '/v2/payers' do
            page = params[:page]
            url = webservices_uri "payers/list_all.json"
            response = rescue_service_call 'List All Payers' do 
              RestClient.get(url, {params: {page: page, token: escaped_oauth_token}, api_key: ApiService::APP_API_KEY})
            end
            
            if !response.headers[:link].nil?
              headers['Link'] = PaginationLinkBuilder.new(response.headers[:link], ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['gateway_url'] + env['PATH_INFO'] + '?' + env['QUERY_STRING']).to_s
            end
            
            @payers = JSON.parse(response)
            status HTTP_OK
            jbuilder :list_payers
          end
          
          app.post '/v2/payers/search' do
            request_body = get_request_JSON
            
            if !request_body['terms'].present?
              api_svc_halt HTTP_BAD_REQUEST, '{error: It is required to have at least 1 term.}'
            end
            search_criteria = request_body['terms'].join(' ')

            payerurl = webservices_uri "payers.json"
            response = rescue_service_call 'Search Payers' do
               RestClient.get(payerurl, { params: { search: search_criteria, token: escaped_oauth_token}, api_key: ApiService::APP_API_KEY } )
            end
            @payers = JSON.parse(response)
            status HTTP_OK
            jbuilder :list_payers
          end
          
        end
      end
    end
  end

  register V2::Clinical::Payers
end
