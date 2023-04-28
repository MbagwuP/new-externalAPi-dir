json.id location['id']
json.name location['name']
json.is_visible_appointment_scheduler location['is_visible_appointment_scheduler']
json.place_of_service_code location['place_of_service'] ? location['place_of_service']['code'] : nil
json.address location['address']
json.phones do
  json.array! location['phones'] do |phone|
    json.partial! :phone, phone: phone
  end
end
