class ApiService < Sinatra::Base

  get '/v2/Group/:id/$export' do
    @patients = group_patients(params[:id])
    @patient_ids = @patients.collect {|pat| pat["patient"]["external_id"] }
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    case params[:_type]
      when 'Goal'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Goal',{ccd_component: ['goals']})
          @responses << response if response
        end

        status HTTP_OK
        jbuilder :multipatient_list_goals
      when 'Immunization'
        @responses = []
        @patient_ids.each do |patient_id|
           response = get_response(patient_id,'Immunization',{date: params[:date],status: params[:status]})
           @responses << response[:resources]
        end
        status HTTP_OK
        jbuilder :multipatient_list_immunizations
      when 'Condition'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Condition')
          @responses << response[:resources]
        end
        status HTTP_OK
        jbuilder :multipatient_list_conditions
      when 'Careplan'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Careplan',{ccd_component: ['plan_of_treatment'], summary: params[:summary]})
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_care_plans
      when 'Observation'
        @responses = []
        options = {
            ccd_component: ['social_history'],
            summary: params[:summary],
            code: params[:code],
            category: params[:category]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Observation',options)
          @responses << response
        end
        status HTTP_OK
        if params[:code] == ObservationCode::LABORATORY || params[:category] == 'laboratory'
          jbuilder :multipatient_list_lab_results
        elsif params[:code] == ObservationCode::SMOKING_STATUS
          jbuilder :multipatient_list_observations_smoking_status
        else
          jbuilder :multipatient_list_observations
        end
      else
        status HTTP_OK
        jbuilder :patientlist
    end
  end

end
