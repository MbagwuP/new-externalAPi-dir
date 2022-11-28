encounter = OpenStruct.new(@encounter)
patient = OpenStruct.new(encounter.patient)
business_entity = OpenStruct.new(encounter.business_entity)
nature_of_visit = OpenStruct.new(encounter.nature_of_visit)
location = OpenStruct.new(encounter.location)
clinical_case = OpenStruct.new(encounter.clinical_case)

# build participant array with participant type.
attending_provider = OpenStruct.new(encounter.attending_provider)
attending_provider.participant_type = 'primary performer'
supervising_provider = OpenStruct.new(encounter.supervising_provider)
supervising_provider.participant_type = 'secondary performer'
participants = [attending_provider, supervising_provider]

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
    json.partial! :provider, provider: participant
    json.participant_type participant.participant_type
  end

  json.service_type_code
  json.service_type_code_system
  json.service_type_code_display
  json.priority_code ""
  json.priority_code_system ""
  json.priority_code_display ""
  json.period_start encounter.start_date
  json.period_end encounter.end_date
  json.reason_code ""
  json.reason_code_system ""
  json.reason_code_display ""
  json.reason_text ""

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

  json.healthcare_entity do
    json.partial! :healthcare_entity, healthcare_entity: business_entity
	end

  json.location do
    json.id location.id
    json.name location.name
    json.status location.status
  end

  json.hospitalization
    json.discharge_disposition
      json.code "oth"
      json.code_system "discharge-disposition"
      json.code_display "Other"
    end
  end

end
