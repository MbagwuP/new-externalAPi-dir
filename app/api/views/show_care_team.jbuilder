first_care_team_member = OpenStruct.new(@care_team_members.first)
patient = OpenStruct.new(first_care_team_member.patient)
business_entity = OpenStruct.new(first_care_team_member.business_entity)

json.care_team do
  json.status status_by_any_active_participant(@care_team_members)
  
  json.participant @care_team_members do |ctm|
    json.id ctm['member_guid']
    json.role participant_role(ctm['member_type'])
    json.member ctm['member_full_name']
    json.period_start ctm['effective_from']
    json.period_end ctm['effective_end']
  end
  
  json.patient do
    json.partial! :patient, patient: patient
  end
  
  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end
end
