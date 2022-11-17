class ApiService < Sinatra::Base

  # get '/v2/care_teams/:id' do
  #   immunization_id = params[:id]
  #   base_path = "immunizations/#{immunization_id}.json"
    
  #   resp = evaluate_current_internal_request_header_and_execute_request(
  #     base_path: base_path,
  #     params: {},
  #     rescue_string: 'Immunization'
  #   )

  #   @immunization = resp['immunizations'].first    
  #   status HTTP_OK
  #   jbuilder :show_immunization
  # end


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
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    status HTTP_OK
    # jbuilder :show_care_team
    jbuilder :list_care_team
  end
end
