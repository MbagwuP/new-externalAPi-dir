class ApiService < Sinatra::Base

    get '/v2/provenance/:id' do
      resourceid = params[:id]
      resource, id = resourceid.split('-provenance-')
      case resource
      when "Condition"
        base_path = "assertions/#{id}.json"
        resp = call_resource(base_path, resource)
        @resource = OpenStruct.new(resp['problems'].first)
        @business_entity = OpenStruct.new(@resource.business_entity)
        @patient = OpenStruct.new(@resource.patient)
        @provider = OpenStruct.new(@resource.provider)
        @obj = resource
      when "Goal"
        base_path = "findings/#{id}/find_by_id.json"
        resp = call_resource(base_path, resource)
        @resource = OpenStruct.new resp['finding']
        @patient = OpenStruct.new resp['patient']
        @provider = OpenStruct.new resp['provider']
        @business_entity = OpenStruct.new resp['business_entity']
        @obj = resource
      when "Immunization"
        base_path = "immunizations/#{id}.json"
        resp = call_resource(base_path, resource)
        @resource = OpenStruct.new resp['immunizations'].first  
        @patient = OpenStruct.new(@resource.patient)
        @provider = OpenStruct.new(@resource.provider)
        @business_entity = OpenStruct.new(@resource.business_entity)  
        @obj = resource
      when "Procedure"
        base_path = "procedure_orders/find_by_id.json"
        params = {id: id}
        resp = call_resource(base_path, resource, params)
        @resource = OpenStruct.new resp['procedure_order']
        @patient = OpenStruct.new @resource.patient
        @business_entity = OpenStruct.new @resource.business_entity
        @provider = OpenStruct.new @resource.provider
        @obj = resource
      when "patient"
        base_path = "patients/search/v2.json"
        params = { patient_id: id }
        resp = call_resource(base_path, resource, params)
        @resource = OpenStruct.new(resp['patients'][0]["patient"]) 
        @is_patient = true
      when "Device"
        base_path = "implantable_devices/#{id}/find_by_id.json"
        resp = call_resource(base_path, resource)
        @resource = OpenStruct.new resp['implantable_device']
        @patient = OpenStruct.new(@resource.patient)
        @business_entity = OpenStruct.new(:id => @patient.be_id) if @patient.try(:be_id)
        @business_entity = OpenStruct.new(:id => 0) if !@business_entity
        @provider = OpenStruct.new(:id => @patient.provider_id) if @patient.try(:provider_id)
        @provider = OpenStruct.new(:id => 0) if !@provider
        @obj = resource
      when "AllergyIntolerance"
        base_path = "patient_allergies/#{id}.json"
        resp = call_resource(base_path, resource)
        @resource = OpenStruct.new resp['allergies'].first
        @patient = OpenStruct.new(@resource.patient)
        @business_entity = OpenStruct.new(@resource.business_entity)
        @provider = OpenStruct.new(@resource.provider)
        @obj = resource
      when "Smoking-Status"
        base_path = "patient_summary/generate_json_by_patient_id_and_component.json"
        params = {patient_id: id, ccd_components: ['social_history']}
        resp = call_resource(base_path, resource, params)
        patient_summary = resp['patient_summary']
        patient_summary = JSON.parse(patient_summary) if patient_summary
        social_history_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
        social_history = SocialHistorySection.new(social_history_section)
        @resource = OpenStruct.new social_history.entries.first
        @patient = OpenStruct.new resp['patient']['patient']
        @business_entity = OpenStruct.new resp['business_entity']['business_entity']
        @provider = OpenStruct.new resp['provider']
        @obj = resource
      when "CareTeam"
        base_path = "care_team_members/#{id}/find_by_id.json"
        resp = call_resource(base_path, resp)
        @resource = OpenStruct.new resp['care_team_members'].first 
        @patient = OpenStruct.new(@resource.patient)
        @business_entity = OpenStruct.new(@resource.business_entity)
        @provider = OpenStruct.new(@resource.provider)
        @obj = resource
      when "Pulse-Oximetry"
        observation_id_with_enum = id.split("-")
        type_code = observation_id_with_enum.last
        observation_id_with_enum.pop()
        observation_id_array = observation_id_with_enum
        base_path = "vital_observations/list_by_observation_code.json"
        params = {observation_id: observation_id_array}
        resp = call_resource(base_path, resource, params)

        @resource = PulseOximetryObservation.new(resp['observations'])
        @patient = @resource.patient
        @business_entity = @resource.business_entity
        @provider = @resource.provider
        @obj = resource
      when "Blood-pressure"
        observation_id_with_enum = id.split("-")
        type_code = observation_id_with_enum.last
        observation_id_with_enum.pop()
        observation_id_array = observation_id_with_enum
        base_path = "vital_observations/list_by_observation_code.json"
        params = {observation_id: observation_id_array}
        resp = call_resource(base_path, resource, params)
        @resource = BloodPressureObservation.new(resp['observations'])
        @patient = @resource.patient
        @business_entity = @resource.business_entity
        @provider = @resource.provider
        @obj = resource
      when "Observation"
        base_path = "vital_observations/list_by_observation_code.json"
        params = {observation_id: id}
        resp = call_resource(base_path, resource, params)
        @resource = OpenStruct.new resp['observations'].first
        @patient = OpenStruct.new(@resource.patient)
        @business_entity = OpenStruct.new(@resource.business_entity)
        @provider = OpenStruct.new(@resource.provider)
        @obj = resource
      when "CarePlan"
        base_path = "patient_summary/generate_json_by_patient_id_and_component.json"
        params =  { patient_id: id, ccd_components: ['plan_of_treatment'] }
        resp = call_resource(base_path, resource, params)
        patient_summary = resp['patient_summary']
        patient_summary = JSON.parse(patient_summary) if patient_summary
        plan_of_treatment_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']
        @resource = OpenStruct.new PlanOfTreatmentSection.new(plan_of_treatment_section).entries[1]
        @patient = OpenStruct.new resp['patient']['patient']
        @business_entity = OpenStruct.new resp['business_entity']['business_entity']
        @provider = OpenStruct.new resp['provider']
        @obj = resource 
      when "Medication"
        base_path = "businesses/#{current_business_entity}/medications/find_by_id.json"
        params = { id: id }
        resp = call_resource(base_path, resource, params)
        @resource = OpenStruct.new resp['medications'].first
        @patient = OpenStruct.new(@resource.patient)
        @provider = OpenStruct.new(@resource.provider)
        @business_entity = OpenStruct.new(@resource.business_entity)
        @obj = resource 
      when "Document"
        base_path = "documents/#{id}.json"
        params = { id: id }
        resp = call_resource(base_path, resource, params)
        @resource = OpenStruct.new resp['document']
        @business_entity = OpenStruct.new resp["document"]["business_entity"]
        @patient = OpenStruct.new resp["document"]["patient"]
        @provider = OpenStruct.new resp["document"]["provider"]
        @obj = resource
      when "Encounter"
        base_path = "encounters/details/#{encounter_id}.json"
        resp = call_resource(base_path, resource)
        @resource = OpenStruct.new resp['encounter']
        @patient = OpenStruct.new(@resource.patient)
        @business_entity = OpenStruct.new(@resource.business_entity)
        @provider = OpenStruct.new(@resource.attending_provider) || OpenStruct.new(@resource.supervising_provider)
        @obj = resource
      when "DiagnosticReport"
        base_path = "labs/get_results_by_patient_and_code.json"
        parameters = { id: id }
        resp = call_resource(base_path, resource, parameters)
        @resource = resp["lab_results"]["lab_request_test"]
        @resource = OpenStruct.new @resource
        @patient = OpenStruct.new resp["patient"]["patient"]
        @provider = OpenStruct.new resp["provider"]["provider"]
        @business_entity = OpenStruct.new resp["business_entity"]["business_entity"]
        @obj = resource
      when "labResult"
        observation_id_with_enum = id.split("-")
        type_code = observation_id_with_enum.last
        observation_id_with_enum.pop()
        observation_id_array = observation_id_with_enum
        base_path = "labs/get_results_by_patient_and_code.json"
        parameters = { id: observation_id_array[0] }
        resp = call_resource(base_path, resource, parameters)
        @resource = resp["lab_results"]["lab_request_test"]
        @resource["id"] = "#{@resource["id"]}-#{ObservationType::LAB_REQUEST}"
        @resource = OpenStruct.new @resource
        @patient = OpenStruct.new resp["patient"]["patient"]
        @provider = OpenStruct.new resp["provider"]["provider"]
        @business_entity = OpenStruct.new resp["business_entity"]["business_entity"]
        @obj = resource
      end

      status HTTP_OK
      jbuilder :show_provenance
    end


    private
    def call_resource(base_path, resource, params={})
        evaluate_current_internal_request_header_and_execute_request(
            base_path: base_path,
            params: params,
            rescue_string: resource
        )
    end
end