class ApiService < Sinatra::Base

  get '/v2/Group/:id/$export' do
    @patients = group_patients(params[:id])
    @patient_ids = @patients.collect {|pat| pat["patient"]["external_id"] }
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    case params[:_type]
      when 'Goal'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Goal',{ccd_component: ['goals'], summary: params[:_summary]})
          @responses << response if response
        end

        status HTTP_OK
        jbuilder :multipatient_list_goals
      when 'Immunization'
        @responses = []
        options = {
            date: params[:date],
            status: params[:status],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
           response = get_response(patient_id,'Immunization',options)
           @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_immunizations
      when 'Condition'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Condition',{summary: params[:_summary]})
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_conditions
      when 'Careplan'
        @responses = []
        options = {
            ccd_component: ['plan_of_treatment'],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Careplan',options)
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_care_plans
      when 'Careteam'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Careteam', {status: params[:status], summary: params[:_summary]})
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_care_team
      when 'Allergyintolerances'
        @responses = []
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Allergyintolerances', {status: params[:status], summary: params[:_summary]})
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_allergy_intolerance
      when 'Documentreference'
        @responses = []
        options = {
            category: params[:category],
            summary: params[:_summary],
            date: params[:date]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Documentreference',options)
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_document_reference
      when 'Patient'
        @responses = []
        options = {
            name: params[:name],
            dob: params[:birthdate],
            gender: params[:gender],
            mrn: params[:mrn],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Patient',options)
          @responses << response
        end
        status HTTP_OK
        jbuilder :multipatient_list_patients

      when 'Observation'
        @responses = []
        options = {
            ccd_component: ['social_history'],
            summary: params[:_summary],
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
