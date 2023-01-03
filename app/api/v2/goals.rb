class ApiService < Sinatra::Base

  get '/v2/goals' do
    validate_patient_id_param(params[:patient_id])

    response = get_response(params[:patient_id],'Goal',{ccd_components: ['goals']})
    
    @goal = response[:resources]
    @patient = response[:patient]
    @business_entity = response[:business_entity]
    @provider = response[:provider] ? response[:provider]['provider'] : nil

    @contact = response[:contact]
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    if params[:_summary] == "count"
      @count_summary =  @goal.entries.length
    end

    status HTTP_OK
    jbuilder :list_goals
  end

  get '/v2/goals/:id' do
    goal_id = params[:id]
    base_path = "findings/#{goal_id}/find_by_id.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Goal"
    )

    @goal = resp['finding']
    @patient = resp['patient']
    @provider = resp['provider']
    @business_entity = resp['business_entity']
    status HTTP_OK
    jbuilder :show_goal
  end
end
