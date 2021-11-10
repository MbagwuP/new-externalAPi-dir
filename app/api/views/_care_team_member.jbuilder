care_team_member_type = OpenStruct.new(care_team_member.care_team_member_type)

json.id care_team_member.id
# json.code nil
# json.code_system nil
# json.code_display nil
# json.text nil
# json.text_status nil
json.status status_by_dates(care_team_member.effective_from, care_team_member.effective_end)

json.period_start care_team_member.effective_from
json.period_end care_team_member.effective_end