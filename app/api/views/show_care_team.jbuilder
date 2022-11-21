# first_care_team_member = OpenStruct.new(@care_team_members.first)
# patient = OpenStruct.new(first_care_team_member.patient)
# business_entity = OpenStruct.new(first_care_team_member.business_entity)

# json.care_team do
#   json.status status_by_any_active_participant(@care_team_members)

#   json.text 'Care Team'
#   json.text_status 'generated'

#   json.participant @care_team_members do |ctm|
#     role = participant_role(ctm['member_type'])

#     json.id ctm['member_guid']
#     json.role role

#     if role == 'Physician'
#       json.code '158965000'
#       json.code_display 'snomed'
#       json.code_system 'Medical Practicioner'
#     else
#       json.code ''
#       json.code_display ''
#       json.code_system ''
#     end

#     json.member ctm['member_full_name']
#     json.period_start ctm['effective_from']
#     json.period_end ctm['effective_end']
#   end
  
#   json.patient do
#     json.partial! :patient, patient: patient
#   end
  
#   json.business_entity do
#     json.partial! :business_entity, business_entity: business_entity
#   end
# end


json.careTeamEntries @care_team_members do |careTeam|

  careTeam = OpenStruct.new(careTeam)
  patient = OpenStruct.new(careTeam.patient)
  business_entity = OpenStruct.new(careTeam.business_entity)
  provider = OpenStruct.new(careTeam.provider)

  json.careTeam do

    json.account_number patient.external_id
    json.mrn patient.chart_number
    json.patient_name patient.full_name
    json.identifier careTeam.id
    json.text "Care Team"
    json.text_status "generated"
    json.status status_by_dates(careTeam.effective_from, careTeam.effective_end)
    json.period_start careTeam.effective_from
    json.period_end careTeam.effective_end

    json.participant do
      json.array!([:once]) do
        role = participant_role(careTeam['member_type'])
        json.role do
          json.coding do
            json.array!([:once]) do
              if role == 'Physician'
                  json.code '158965000'
                  json.code_display 'snomed'
                  json.code_system 'Medical Practicioner'
              else
                  json.code '116154003'
                  json.code_display 'snomed'
                  json.code_system 'Patient'
              end
            end
          end
          if role == 'Physician'
            json.text 'Medical Practicioner'
          else
            json.text 'Patient'
          end
          
        end
        json.member do
          if role == 'Physician'
            json.reference "Practitioner/#{careTeam['member_id']}"
            json.display careTeam['member_full_name']
          else
            json.reference "Patient/#{patient.external_id}"
            json.display patient.full_name
          end
        end    
      end
    end
    
    json.healthcare_entity do
      json.partial! :healthcare_entity, healthcare_entity: business_entity
    end

    if @include_provenance_target
	    json.partial! :_provenance, patient: patient, record: careTeam, 
      provider: provider, business_entity: business_entity, obj: 'CareTeam'
    end
  end
end

