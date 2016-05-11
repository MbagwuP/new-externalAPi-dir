json.array! @resp do |appt|
  json.partial! :appointment, appointment: appt
end
