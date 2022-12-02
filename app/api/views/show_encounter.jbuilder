
if @summary == 'count'
  json.resource_count 1
else

  encounter = OpenStruct.new(@encounter)
  patient = OpenStruct.new(encounter.patient)
  business_entity = OpenStruct.new(encounter.business_entity)
  nature_of_visit = OpenStruct.new(encounter.nature_of_visit)
  location = OpenStruct.new(encounter.location)
  clinical_case = OpenStruct.new(encounter.clinical_case)

  #build participant array with participant type.
  attending_provider = OpenStruct.new(encounter.attending_provider)
  supervising_provider = OpenStruct.new(encounter.supervising_provider)
  participants = []
  if attending_provider.id.present?
    attending_provider.participant_type = 'primary performer'
    participants << attending_provider
  end
  if supervising_provider.id.present?
    supervising_provider.participant_type = 'secondary performer'
    participants << supervising_provider
  end

  json.encounter do
    json.account_number patient.external_id
    json.mrn patient.chart_number
    json.patient_name patient.full_name
    json.identifier encounter.id
    json.status encounter_status(encounter.status)
    json.encounter_code "AMB"
    json.encounter_code_system "v3-ActCode"
    json.encounter_code_display "ambulatory"
    json.type_code nature_of_visit.code
    json.type_code_system "snomed"
    json.type_code_display nature_of_visit.name

    json.participant participants do |participant|
      json.type do
        json.code participant.envoy_site_number #add to webservices
        json.code_system "v3-ParticipationType"
        json.code_display participant.participant_type
      end

      json.period do
        json.start encounter.start_time #participant.effective_from #add to webservices
        json.end encounter.end_time #participant.effective_to #add to webservices
      end

      json.individual do
        json.reference "Practitioner" + '/' + participant.id.to_s
      end
    end

    json.service_type_code nil
    json.service_type_code_system nil
    json.service_type_code_display nil
    json.priority_code nil
    json.priority_code_system nil
    json.priority_code_display nil
    json.period_start encounter.start_time #encounter.date_of_service #add to webservices
    json.period_end encounter.end_time
    json.reason_code nature_of_visit.code
    json.reason_code_system "snomed"
    json.reason_code_display nature_of_visit.name
    json.reason_text nature_of_visit.description

    json.provider do
      json.identifier attending_provider.id
      json.npi attending_provider.npi
      json.last_name attending_provider.last_name
      json.first_name attending_provider.first_name
    end

    json.responsible_provider do
      json.identifier supervising_provider.id
      json.npi supervising_provider.npi
      json.last_name supervising_provider.last_name
      json.first_name supervising_provider.first_name
    end

    json.location do
      json.identifier location.id
      json.name location.name
      #json.status location.status
    end

    json.healthcare_entity do
      json.partial! :healthcare_entity, healthcare_entity: business_entity
  	end

    json.hospitalization do
      json.discharge_disposition do
        json.code "oth"
        json.code_system "discharge-disposition"
        json.code_display "Other"
      end
    end

  end

  if @include_provenance_target
    provider_object = attending_provider
    provider_object = OpenStruct.new(:id => 0) if !provider_object

    be_object = business_entity
    be_object = OpenStruct.new(:id => 0) if !be_object

    location_object = location
    location_object = OpenStruct.new(:id => 0) if !location_object

    json.partial! :provenance, patient: patient, record: encounter, provider: provider_object, business_entity: be_object, location: location_object, obj: 'Encounter'
  end

end #@summary
