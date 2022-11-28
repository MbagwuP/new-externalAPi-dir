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

# json.encounter do
#   json.partial! :encounter, encounter: encounter
#   json.status encounter_status(encounter.status)
#   json.period_start encounter.start_time
#   json.period_end encounter.end_time
#   json.priority_code ""
#   json.priority_code_system ""
#   json.priority_code_display ""
#   json.type_code nature_of_visit.code
#   json.type_code_system ""
#   json.type_code_display nature_of_visit.name

#   json.location do
#     json.id location.id
#     json.name location.name
#     json.status location.status
#   end

#   json.participants participants do |participant|
#     json.partial! :provider, provider: participant
#     json.participant_type participant.participant_type
#   end

#   json.patient do
#     json.partial! :patient, patient: patient
#   end
  
#   json.business_entity do
#     json.partial! :business_entity, business_entity: business_entity
#   end
# end

json.encounter do
  json.account_number patient.external_id
  json.mrn patient.chart_number
  json.patient_name patient.full_name
  json.identifier encounter.id
  json.status encounter_status(encounter.status)
  json.encounter_code
  json.encounter_code_system
  json.encounter_code_display
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
  json.reason_code
  json.reason_code_system
  json.reason_code_display
  json.reason_text

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
  
end



# {
#     "encounter": {
#         "account_number": "1000000000048701",
#         "mrn": "00000048701",
#         "patient_name": "ALICE NEWMAN",
#         "identifier": 10000453,
#         "status": "in-progress",
#         "encounter_code": "AMB",
#         "encounter_code_system": "v3-ActCode",
#         "encounter_code_display": "ambulatory",
#         "type_code": "308335008",
#         "type_code_system": "snomed",
#         "type_code_display": "Patient encounter procedure",
#         "participant": [
#             {
#                 "type": {
#                     "code": "PPRF",
#                     "code_system": "v3-ParticipationType",
#                     "code_display": "primary performer"
#                 },
#                 "period": {
#                     "start": "2005-05-01T12:57:00-05:00",
#                     "end": "2005-05-01T12:57:00-05:00"
#                 },
#                 "individual": {
#                     "reference": "Practitioner/100000011667"
#                 }
#             }
#         ],
#         "service_type_code": null,
#         "service_type_code_system": null,
#         "service_type_code_display": null,
#         "priority_code": null,
#         "priority_code_system": null,
#         "priority_code_display": null,
#         "period_start": "2005-05-01T12:57:00-05:00",
#         "period_end": "2005-05-01T12:57:00-05:00",
#         "reason_code": "308335008",
#         "reason_code_system": "snomed",
#         "reason_code_display": "Patient encounter procedure",
#         "reason_text": null,
#         "provider": {
#             "identifier": 100000011667,
#             "npi": "5331549071",
#             "last_name": "DAVIS",
#             "first_name": "ALBERT"
#         },
#         "responsible_provider": {
#             "identifier": null,
#             "npi": null,
#             "last_name": null,
#             "first_name": null
#         },
#         "location": {
#             "identifier": 100006,
#             "name": "NEIGHBORHOOD PHYSICIANS PRACTICE"
#         },
#         "healthcare_entity": {
#             "identifier": 10000,
#             "name": "DRUMMOND"
#         },
#         "hospitalization": {
#             "discharge_disposition": {
#                 "code": "oth",
#                 "code_system": "discharge-disposition",
#                 "code_display": "Other"
#             }
#         }
#     }
# }