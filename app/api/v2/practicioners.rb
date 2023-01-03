class ApiService < Sinatra::Base
  get '/v2/practitioner/:id' do
    practicioner_id = params[:id]
    business_entity_id = current_business_entity
    base_path = "businesses/#{business_entity_id}/providers/#{practicioner_id}/details.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Practicioner '
    ) 

    @practicioner = OpenStruct.new(resp['provider'])

    status HTTP_OK
    jbuilder :show_practicioner
  end
end

