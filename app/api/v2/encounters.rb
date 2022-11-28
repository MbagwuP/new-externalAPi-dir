class ApiService < Sinatra::Base

  get '/v2/encounter/:id' do
    encounter_id = params[:id]
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
