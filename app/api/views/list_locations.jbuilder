json.locations do
  json.array! @locations['locations'] do |location|
    json.partial! :location, location: location
  end
end