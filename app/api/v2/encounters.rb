class ApiService < Sinatra::Base

  get '/v2/encounter/:id' do
    encounter_id = params[:id]
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    @summary = params[:_summary] if params[:_summary].present?

    #base_path = "encounters/#{encounter_id}/details.json"
    base_path = "encounters/details/#{encounter_id}.json"
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Encounter '
    )

    @encounter = resp['encounter']
    
    status HTTP_OK
    jbuilder :show_encounter
  end
end
