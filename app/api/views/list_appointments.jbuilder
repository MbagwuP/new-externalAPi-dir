json.array! @resp do |appt|
  json.appointment do
    json.partial! :appointment, appointment: appt['appointment']
  end
end
