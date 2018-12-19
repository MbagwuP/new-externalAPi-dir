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
    if note['note_trigger']['expires_at'].nil?
      json.expires_at nil
    else 
      json.expires_at Date.parse(note['note_trigger']['expires_at']).try(:to_s)
    end
  end
end