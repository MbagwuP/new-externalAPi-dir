class ApiService < Sinatra::Base

  get '/v2/Group/:id/$export' do
    @patients = group_patients(params[:id])
    @patient_ids = @patients.collect {|pat| pat["patient"]["external_id"] }

    case params[:_type]
      when 'Goal'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Goal',['goals'])

          @responses << response if response
        end

        @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

        status HTTP_OK
        jbuilder :multipatient_list_goals
      else

        status HTTP_OK
        jbuilder :patientlist
    end
  end

end
