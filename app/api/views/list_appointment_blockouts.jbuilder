json.array! @blockouts do |blockout|
  json.set! :appointment_blockout do
    json.business_entity_id blockout['appointment_blockout']['business_entity_guid']
    json.created_at blockout['appointment_blockout']['created_at']
    json.description blockout['appointment_blockout']['description']
    json.effective_from blockout['appointment_blockout']['effective_from']
    json.effective_to blockout['appointment_blockout']['effective_to']
    json.id blockout['appointment_blockout']['id']
    json.name blockout['appointment_blockout']['name']
    json.start_at blockout['appointment_blockout']['start_at']
    json.end_at blockout['appointment_blockout']['end_at']
    json.use_sunday blockout['appointment_blockout']['use_sunday']
    json.use_monday blockout['appointment_blockout']['use_monday']
    json.use_tuesday blockout['appointment_blockout']['use_tuesday']
    json.use_wednesday blockout['appointment_blockout']['use_wednesday']
    json.use_thursday blockout['appointment_blockout']['use_thursday']
    json.use_friday blockout['appointment_blockout']['use_friday']
    json.use_saturday blockout['appointment_blockout']['use_saturday']
    json.timezone_name blockout['appointment_blockout']['timezone_name']
    json.recurrence_id blockout['appointment_blockout']['recurrence_id']
    json.updated_at blockout['appointment_blockout']['updated_at']
    # json.frequency_description blockout['appointment_blockout']['frequency_description']
    json.occurrences blockout['appointment_blockout']['occurrences']
    json.resources blockout['appointment_blockout']['resources'] do |resource|
      json.id resource['resource']['id']
      json.name resource['resource']['name']
    end
    json.locations blockout['appointment_blockout']['locations'] do |location|
      json.id location['location']['id']
      json.name location['location']['name']
    end
    
  end
end