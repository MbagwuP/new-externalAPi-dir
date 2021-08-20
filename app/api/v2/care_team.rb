class ApiService < Sinatra::Base

  get '/v2/care_teams' do
    patient_id = params[:patient_id]
    
    validate_patient_id_param(patient_id)

    base_path = "businesses/#{current_business_entity}/patients/#{patient_id}/care_team_members.json"
  
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Care team members"
    )

    @care_team_members = resp['care_team_members']

    status HTTP_OK
    jbuilder :show_care_team
  end
end
