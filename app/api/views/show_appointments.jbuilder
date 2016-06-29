json.array! @resp do |appt|
  json.partial! :appointment_extended, appointment: appt['appointment']
end