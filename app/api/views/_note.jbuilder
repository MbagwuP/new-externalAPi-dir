json.id note['id']
json.text note['text']
if note['note_trigger']['triggers'].nil?
  json.note_trigger nil
else
  json.note_trigger do
    json.actions note['note_trigger']['triggers'] do |trigger|
      json.name trigger['note_trigger']['name']
      json.code trigger['note_trigger']['code']
    end
  json.expires_at Date.parse(note['note_trigger']['expires_at']).try(:to_s) || nil
  end
end