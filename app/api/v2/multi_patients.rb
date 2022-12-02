class ApiService < Sinatra::Base

  get '/v2/Group/:id/export' do
    @patients = group_patients(params[:id])
    @patient_ids = @patients.collect {|pat| pat["patient"]["external_id"] }
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    @all_resource_count = 0
    @total_counts = []
    if params[:_resource_counts] == "true"
      ActCertification::Types.keys.each do |key|
        begin
          process_call(key,params,@patient_ids)
        ensure
          next
        end
      end
      counts = {
          fhir_resource: 'Provenance ',
          count: @all_resource_count
      }
      @all_resource_count = @all_resource_count * 2
      @total_counts << counts
    else
      type = params[:_type]
      process_call(type,params,@patient_ids)
    end
    status HTTP_OK
    if params[:_type] == "Observation"
      if params[:code] == ObservationCode::LABORATORY || params[:category] == 'laboratory'
        jbuilder :multipatient_list_lab_results
      elsif params[:code] == ObservationCode::SMOKING_STATUS
        jbuilder :multipatient_list_observations_smoking_status
      else
        jbuilder :multipatient_list_observations
      end
    elsif params[:_resource_counts] == "true"
      jbuilder :multipatient_resource_counts
    else
      if !params[:_type].nil?
        jbuilder ActCertification::Types[params[:_type].to_sym].to_sym
      else
        jbuilder :patientlist
      end
    end
  end

  def process_call(type,params,patient_ids)
    @patient_ids = patient_ids
    case type.to_s
      when 'Goal'
        @responses = []
        options = {
            resource_counts: params[:_resource_counts],
            ccd_component: ['goals'],
            summary: params[:_summary]
        }
        resource_counts = 0
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Goal',options)
          @responses << response if response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @res = []
        @responses =  @responses.flatten.to_a
        @responses.each do |obj|
          obj[:resources].entries.each do |ele|
            @res << {goal: ele, patient: obj[:patient], provider: obj[:provider], business_entity: obj[:business_entity], contact: obj[:contact],
                     count_summary: obj[:count_summary]}
          end
        end
        @responses = @res
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Goal',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_goals
      when 'Immunization'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            date: params[:date],
            status: params[:status],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Immunization',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end

        @responses =  @responses.flatten.to_a
        @res = []
        @responses.each do |res|
          @res << res[:resources]
        end
        @responses = @res.flatten.to_a
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Immunization',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_immunizations
      when 'Location'
        counts = {
            fhir_resource: 'Location',
            count: 0
        }
        @total_counts << counts
      when 'Encounter'
        counts = {
            fhir_resource: 'Encounter',
            count: 0
        }
        @total_counts << counts
      when 'Condition'
        @responses = []
        resource_counts = 0
        options = {
            summary: params[:_summary],
            resource_counts: params[:_resource_counts]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Condition',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @responses =  @responses.flatten.to_a
        @res = []
        @responses.each do |res|
          @res << res[:resources]
        end
        @responses = @res.flatten.to_a
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Condition',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_conditions
      when 'CarePlan'
        @responses = []
        resource_counts = 0
        options = {
            ccd_component: ['plan_of_treatment'],
            resource_counts: params[:_resource_counts],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'CarePlan',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @res = []
        @responses =  @responses.flatten.to_a
        @responses.each do |obj|
          obj[:resources].entries.each do |ele|
            @res << {carePlan: ele, patient: obj[:patient], provider: obj[:provider], business_entity: obj[:business_entity], contact: obj[:contact]}
          end
        end
        @responses = @res
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'CarePlan',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_care_plans
      when 'CareTeam'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            status: params[:status],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'CareTeam',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @responses =  @responses.flatten.to_a
        @res = []
        @responses.each do |res|
          @res << res[:resources]
        end
        @responses = @res.flatten.to_a
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'CareTeam',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_care_team
      when 'AllergyIntolerances'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            status: params[:status],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'AllergyIntolerances',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @responses =  @responses.flatten.to_a
        @res = []
        @responses.each do |res|
          @res << res[:resources]
        end
        @responses = @res.flatten.to_a
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'AllergyIntolerances',
            count: resource_counts
        }
        @total_counts << counts

        # status HTTP_OK

      when 'Procedure'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Procedure',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @responses =  @responses.flatten.to_a
        @res = []
        @responses.each do |res|
          @res << res[:resources]
        end
        @responses = @res.flatten.to_a
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Procedure',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_procedures
      when 'Device'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Device',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @res = []
        @responses =  @responses.flatten.to_a
        @responses.each do |obj|
          obj[:resources].each do |ele|

            @res << {medical_device: ele}
          end
        end
        @responses = @res
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Device',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_medical_devices

      when 'Medication'
        @responses = []
        resource_counts = 0
        options = {
            status: params[:status],
            resource_counts: params[:_resource_counts],
            summary: params[:_summary],
            intent: params[:intent]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Medication',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end

        if params[:intent]
          @include_intent_target = params[:intent].split(",") if params[:intent].include? ","
          @include_intent_target  = [params[:intent]]  unless params[:intent].include? ","
        else
          @include_intent_target  = []
        end

        if options[:status]
          @include_status_target = params[:status].split(",") if params[:status].include? ","
          @include_status_target = [params[:status]] unless params[:status].include? ","
        else
          @include_status_target = []
        end

        @res = []
        @responses =  @responses.flatten.to_a
        @responses.each do |obj|
          obj[:resources].entries.each do |ele|
            @res << {medication: ele, count_summary: ele[:count_summary]}
          end
        end
        @responses = @res
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Medication',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_medication_orders
      when 'DocumentReference'
        @responses = []
        resource_counts = 0
        options = {
            category: params[:category],
            resource_counts: params[:_resource_counts],
            summary: params[:_summary],
            date: params[:date]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'DocumentReference',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @res = []
        @responses =  @responses.flatten.to_a
        @responses.each do |obj|
          obj[:resources].entries.each do |ele|
            @res << {doc: ele, count_summary: ele[:count_summary]}
          end
        end
        @responses = @res
        @category = params[:category] || "clinical-note"
        @date = params[:date] || nil
        @type = type || "11502-2"

        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'DocumentReference',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_document_reference
      when 'DiagnosticReport'
        @responses = []
        resource_counts = 0
        options = {
            summary: params[:_summary],
            resource_counts: params[:_resource_counts],
            ccd_components: ['labresults']
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'DiagnosticReport',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'DiagnosticReport',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_diagnostic_reports
      when 'Patient'
        @responses = []
        resource_counts = 0
        options = {
            name: params[:name],
            resource_counts: params[:_resource_counts],
            dob: params[:birthdate],
            gender: params[:gender],
            mrn: params[:mrn],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Patient',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Patient',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_patients

      when 'Observation'
        @responses = []
        resource_counts = 0
        options = {
            ccd_component: ['social_history'],
            resource_counts: params[:_resource_counts],
            summary: params[:_summary],
            code: params[:code],
            category: params[:category]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Observation',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end

        unless params[:code] == ObservationCode::LABORATORY || params[:category] == 'laboratory' || params[:code] == ObservationCode::SMOKING_STATUS
          @res = []
          @responses =  @responses.flatten.to_a
          @responses.each do |obj|
            obj[:resources].each do |ele|
              @res << {observation: ele, blood_pressure_observation: obj[:blood_pressure_observation],
                       pulse_oximetry_observation: obj[:pulse_oximetry_observation], count_summary: obj[:count_summary]}
              end
            end
          @responses = @res
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Observation',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
      when 'Organization'
        resource_counts = 0
        base_path = "businesses/#{current_business_entity}/details.json" 
        resp = evaluate_current_internal_request_header_and_execute_request(
          base_path: base_path,
          params: {},
          rescue_string: 'Organization '
        )
        @responses = resp['business_entity']
        @count_summary =  resp.length
        resource_counts = @count_summary

        @all_resource_count = @all_resource_count + resource_counts

        counts = {
            fhir_resource: 'Organization',
            count: resource_counts
        }
        @total_counts << counts
      else
    end
  end

end
