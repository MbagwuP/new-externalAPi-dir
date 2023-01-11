class ApiService < Sinatra::Base

  get '/v2/immunizations/:id' do
    immunization_id = params[:id]
    base_path = "immunizations/#{immunization_id}.json"
    
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Immunization'
    )

    @immunization = resp['immunizations'].first    
    status HTTP_OK
    jbuilder :show_immunization
  end

  get '/v2/immunizations' do
    response = get_response(params[:patient_id],'Immunization',{date: params[:date],status: params[:status]})
    
    @immunizations = response[:resources]
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    if params[:_summary] == "count"
      @count_summary =  @immunizations.length
    end
    status HTTP_OK
    jbuilder :list_immunizations
  end
end
