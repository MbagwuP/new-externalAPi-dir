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
  json.partial! :encounter, encounter: encounter
  json.status encounter_status(encounter.status)
  json.period_start encounter.start_time
  json.period_end encounter.end_time
  json.priority_code ""
  json.priority_code_system ""
  json.priority_code_display ""
  json.type_code nature_of_visit.code
  json.type_code_system ""
  json.type_code_display nature_of_visit.name

  json.location do
    json.id location.id
    json.name location.name
    json.status location.status
  end

  json.participants participants do |participant|
    json.partial! :provider, provider: participant
    json.participant_type participant.participant_type
  end

  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
