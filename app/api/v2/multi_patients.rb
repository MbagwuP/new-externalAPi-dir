class ApiService < Sinatra::Base

  get '/v2/Group/:id/$export' do
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
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Immunization',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_immunizations
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
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Condition',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_conditions
      when 'Careplan'
        @responses = []
        resource_counts = 0
        options = {
            ccd_component: ['plan_of_treatment'],
            resource_counts: params[:_resource_counts],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Careplan',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Careplan',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_care_plans
      when 'Careteam'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            status: params[:status],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Careteam',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Careteam',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_care_team
      when 'Allergyintolerances'
        @responses = []
        resource_counts = 0
        options = {
            resource_counts: params[:_resource_counts],
            status: params[:status],
            summary: params[:_summary]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Allergyintolerances',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Allergyintolerances',
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
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Medication',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_medication_orders
      when 'Documentreference'
        @responses = []
        resource_counts = 0
        options = {
            category: params[:category],
            resource_counts: params[:_resource_counts],
            summary: params[:_summary],
            date: params[:date]
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Documentreference',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Documentreference',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK
        # jbuilder :multipatient_list_document_reference
      when 'Diagnosticreport'
        @responses = []
        resource_counts = 0
        options = {
            summary: params[:_summary],
            resource_counts: params[:_resource_counts],
            ccd_components: ['labresults']
        }
        @patient_ids.each do |patient_id|
          response = get_response(patient_id,'Diagnosticreport',options)
          @responses << response
          resource_counts = resource_counts + (response[:count_summary] || 0) if response
        end
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Diagnosticreport',
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
        @all_resource_count = @all_resource_count + resource_counts
        counts = {
            fhir_resource: 'Observation',
            count: resource_counts
        }
        @total_counts << counts
        # status HTTP_OK

      else

    end
  end

end
