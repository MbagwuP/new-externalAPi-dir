json.location do
  json.partial! :location, location: @location

  json.business_entity do
    json.partial! :business_entity, business_entity: @business_entity
  end
end
