class ApiService < Sinatra::Base

  get '/v2/Group/:id/$export' do
    @patients = group_patients(params[:id])
    @patient_ids = @patients.collect {|pat| pat["patient"]["external_id"] }
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    case params[:_type]
      when 'Goal'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Goal',['goals'])

          @responses << response if response
        end

        status HTTP_OK
        jbuilder :multipatient_list_goals
      when 'Immunization'
        @responses = []
        @patient_ids.each do |patient_id|
           response = get_response(patient_id,'Immunization',nil,params[:date],params[:status])
           @responses << response[:resources]
        end
        binding.pry
        status HTTP_OK
        jbuilder :multipatient_list_immunizations
      else
        status HTTP_OK
        jbuilder :patientlist
    end
  end

end
