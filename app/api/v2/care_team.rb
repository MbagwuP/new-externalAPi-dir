class ApiService < Sinatra::Base

  get '/v2/careteam/:id' do
    care_team_id = params[:id]

    base_path ="care_team_members/#{care_team_id}/find_by_id.json"
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Care Team'
    )
    puts "######## #{resp}"
    @careTeam = resp['care_team_members'].first    
    status HTTP_OK
    jbuilder :show_care_team
  end

  get '/v2/careteam' do
    patient_id = params[:patient_id]
    care_team_status = params[:status]
    validate_patient_id_param(patient_id)

    base_path = "businesses/#{current_business_entity}/patients/#{patient_id}/care_team_members.json"
  
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { status: care_team_status,},
      rescue_string: "Care team members"
    )
    puts "response: #{resp}"

#     resp = JSON.parse('{
#     "care_team_members": [
#         {
#             "id": 3010241,
#             "member_id": 1479960,
#             "member_type": "Physician",
#             "notes": null,
#             "created_at": "2018-10-24T06:48:56-04:00",
#             "effective_from": "2018-10-01T08:00:00-04:00",
#             "effective_to": null,
#             "person_relationship_type_id": null,
#             "last_letter_sent_date": null,
#             "default_letter_template_id": null,
#             "original_id": null,
#             "member_full_name": "ALBERT DAVIS",
#             "member_guid": "PHYS_1479960",
#             "business_entity": {
#                 "id": 15480,
#                 "name": "ONC15 DO NOT USE"
#             },
#             "patient": {
#                 "id": 32524585,
#                 "patient_number": "0068502-6970911100",
#                 "full_name": "ALICE J NEWMAN PH.D",
#                 "chart_number": "2362",
#                 "external_id": "9e8a6b10-5e7f-4ace-840a-804183c64b9d",
#                 "provider_id": "19796",
#                 "be_id": "15480"
#             },
#             "provider": {
#                 "id": 19796,
#                 "npi": "1215980438"
#             }
#         },
#         {
#             "id": 3010242,
#             "member_id": 24449866,
#             "member_type": "Vo::Person",
#             "notes": null,
#             "created_at": "2018-10-24T06:53:54-04:00",
#             "effective_from": "2018-10-01T08:00:00-04:00",
#             "effective_to": null,
#             "person_relationship_type_id": 9,
#             "last_letter_sent_date": null,
#             "default_letter_template_id": null,
#             "original_id": null,
#             "member_full_name": " ",
#             "member_guid": "24449866",
#             "business_entity": {
#                 "id": 15480,
#                 "name": "ONC15 DO NOT USE"
#             },
#             "patient": {
#                 "id": 32524585,
#                 "patient_number": "0068502-6970911100",
#                 "full_name": "ALICE J NEWMAN PH.D",
#                 "chart_number": "2362",
#                 "external_id": "9e8a6b10-5e7f-4ace-840a-804183c64b9d",
#                 "provider_id": "19796",
#                 "be_id": "15480"
#             },
#             "provider": {
#                 "id": 19796,
#                 "npi": "1215980438"
#             }
#         },
#         {
#             "id": 3010243,
#             "member_id": 24447892,
#             "member_type": "Vo::Person",
#             "notes": null,
#             "created_at": "2018-10-24T06:55:01-04:00",
#             "effective_from": "2018-10-01T08:00:00-04:00",
#             "effective_to": null,
#             "person_relationship_type_id": 2,
#             "last_letter_sent_date": null,
#             "default_letter_template_id": null,
#             "original_id": null,
#             "member_full_name": " ",
#             "member_guid": "24447892",
#             "business_entity": {
#                 "id": 15480,
#                 "name": "ONC15 DO NOT USE"
#             },
#             "patient": {
#                 "id": 32524585,
#                 "patient_number": "0068502-6970911100",
#                 "full_name": "ALICE J NEWMAN PH.D",
#                 "chart_number": "2362",
#                 "external_id": "9e8a6b10-5e7f-4ace-840a-804183c64b9d",
#                 "provider_id": "19796",
#                 "be_id": "15480"
#             },
#             "provider": {
#                 "id": 19796,
#                 "npi": "1215980438"
#             }
#         },
#         {
#             "id": 3010244,
#             "member_id": 24447893,
#             "member_type": "Vo::Person",
#             "notes": null,
#             "created_at": "2018-10-24T06:55:31-04:00",
#             "effective_from": "2018-10-01T08:00:00-04:00",
#             "effective_to": null,
#             "person_relationship_type_id": 6,
#             "last_letter_sent_date": null,
#             "default_letter_template_id": null,
#             "original_id": null,
#             "member_full_name": " ",
#             "member_guid": "24447893",
#             "business_entity": {
#                 "id": 15480,
#                 "name": "ONC15 DO NOT USE"
#             },
#             "patient": {
#                 "id": 32524585,
#                 "patient_number": "0068502-6970911100",
#                 "full_name": "ALICE J NEWMAN PH.D",
#                 "chart_number": "2362",
#                 "external_id": "9e8a6b10-5e7f-4ace-840a-804183c64b9d",
#                 "provider_id": "19796",
#                 "be_id": "15480"
#             },
#             "provider": {
#                 "id": 19796,
#                 "npi": "1215980438"
#             }
#         }
#     ]
# }')

    @care_team_members = resp['care_team_members']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    puts "@include_provenance_target #{@include_provenance_target}"
    status HTTP_OK
    # jbuilder :show_care_team
    jbuilder :list_care_team
  end
end
