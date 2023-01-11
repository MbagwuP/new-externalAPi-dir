class ApiService < Sinatra::Base
  get '/v2/organization/:id' do
    organization_id = params[:id]
    base_path = "businesses/#{organization_id}/details.json" 

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Organization '
    )
    
    @organization = resp['business_entity']
    status HTTP_OK
    jbuilder :show_organization
  end
end
