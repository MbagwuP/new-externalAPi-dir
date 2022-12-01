class ApiService < Sinatra::Base

  get '/v2/observations' do
    patient_id = params[:patient_id]
    validate_patient_id_param(patient_id)

    base_path = get_observations_path(params[:code])
    code = get_observations_code(params[:code])
    parameters = { patient_id: patient_id, code: code, date: params[:date], ccd_components: ['social_history'] }

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: "Observation"
    )

    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    if params[:code] == ObservationCode::LABORATORY || params[:category] == 'laboratory'
      @lab_results = resp['lab_request_test_results']
      @observation_type = ObservationType::LAB_REQUEST

      if params[:_summary] == "count"
        @count_summary =  @lab_results.ObservationEntries.length
      end

      status HTTP_OK
      jbuilder :list_lab_results
    elsif params[:code] == ObservationCode::SMOKING_STATUS
      patient_summary = resp['patient_summary']
      patient_summary = JSON.parse(patient_summary) if patient_summary

      social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
   
      @social_history = SocialHistorySection.new(social_history_section)
      @patient = resp['patient']['patient']
      @business_entity = resp['business_entity']['business_entity']
      @provider = resp['provider']['provider']
      @contact = resp['contact']

      if params[:_summary] == "count"
        @count_summary =  @social_history.entries.length
      end

      status HTTP_OK
      jbuilder :list_observations_smoking_status
    else
      @blood_pressure_observation = BloodPressureObservation.new(resp['observations']) if resp['observations'].select{|a| a['code'] == ObservationCode::SYSTOLIC}.present?
      @pulse_oximetry_observation = PulseOximetryObservation.new(resp['observations']) if resp['observations'].select{|a| a['code'] == ObservationCode::OXYGEN_SATURATION}.present?

      @observation_entries = resp['observations'].reject{|a| [ObservationCode::SYSTOLIC,ObservationCode::DIASTOLIC,ObservationCode::OXYGEN_SATURATION,ObservationCode::INHALED_OXYGEN_CONCENTRATION].include? a['code']}
      @observation_entries << @blood_pressure_observation if @blood_pressure_observation.present?
      @observation_entries << @pulse_oximetry_observation if @pulse_oximetry_observation.present?
      @observation_type = ObservationType::VITAL_SIGNS

      if params[:_summary] == "count"
        @count_summary =  @observation_entries.entries.length
      end

      status HTTP_OK
      jbuilder :list_observations
    end
  end


  # /v2/observations/{guid}
  # /v2/observations/{integer_id}
  get /\/v2\/observations\/(?<observation_id>[\w-]*)$/ do |observation_id|
    observation_id_with_enum = params[:observation_id].split("-")
    type_code = observation_id_with_enum.last
    observation_id_with_enum.pop()
    observation_id_array = observation_id_with_enum
    case type_code.to_i
    when ObservationType::LAB_REQUEST
    #Smoking Status - patient id is used as observation id
    when ObservationType::SMOKING_STATUS
      patient_id = params[:observation_id].chop.chop
      base_path = "patient_summary/generate_json_by_patient_id_and_component.json"
      resp = evaluate_current_internal_request_header_and_execute_request(
        base_path: base_path,
        params: {patient_id: patient_id, ccd_components: ['social_history']},
        rescue_string: "Observation"
      )
      patient_summary = resp['patient_summary']
      patient_summary = JSON.parse(patient_summary) if patient_summary

      social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
   
      @social_history = SocialHistorySection.new(social_history_section)
      @patient = resp['patient']['patient']
      @business_entity = resp['business_entity']['business_entity']
      @provider = resp['provider']
      @contact = resp['contact']
      status HTTP_OK
      jbuilder :show_smoking_status_observation

    when ObservationType::BLOOD_PRESSURE
      base_path = "vital_observations/list_by_observation_code.json"
      resp = evaluate_current_internal_request_header_and_execute_request(
        base_path: base_path,
        params: {observation_id: observation_id_array},
        rescue_string: "Observation"
      )
      @blood_pressure_observation = BloodPressureObservation.new(resp['observations'])
      status HTTP_OK
      jbuilder :show_blood_pressure_observation

    when ObservationType::PULSE_OXIMETRY
      base_path = "vital_observations/list_by_observation_code.json"
      resp = evaluate_current_internal_request_header_and_execute_request(
        base_path: base_path,
        params: {observation_id: observation_id_array},
        rescue_string: "Observation"
      )
      @pulse_oximetry_observation = PulseOximetryObservation.new(resp['observations'])
      status HTTP_OK
      jbuilder :show_pulse_oximetry_observation

    else
      base_path = "vital_observations/list_by_observation_code.json"
      resp = evaluate_current_internal_request_header_and_execute_request(
        base_path: base_path,
        params: {observation_id: observation_id_array},
        rescue_string: "Observation"
      )
      @observation = resp['observations'].first
      @observation_type = type_code
      status HTTP_OK
      jbuilder :show_observation
    end
  end
end