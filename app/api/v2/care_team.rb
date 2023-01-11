class ApiService < Sinatra::Base

  get '/v2/careteam/:id' do

    care_team_id = params[:id]
    base_path ="care_team_members/#{care_team_id}/find_by_id.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Care Team'
    )

    @careTeam = resp['care_team_members'].first    
    status HTTP_OK
    jbuilder :show_care_team
  end

  get '/v2/careteam' do
    patient_id = params[:patient_id]
    care_team_status = params[:status]
    validate_patient_id_param(patient_id)

    base_path = "businesses/#{current_business_entity}/patients/#{patient_id}/care_team_members.json"
  
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { status: care_team_status,},
      rescue_string: "Care team members"
    )

    @care_team_members = resp['care_team_members']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    if params[:_summary] == "count"
      @count_summary =  @care_team_members.length
    end
    status HTTP_OK
    jbuilder :list_care_team
  end
end
