json.array! @resp do |confirmation|
   json.partial! :appointment_confirmation, :@confirmation => confirmation, :@appointment_id => @appointment_id
end
