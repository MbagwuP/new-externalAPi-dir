json.array! @resp do |medication|
  json.partial! :medication, medication: OpenStruct.new(medication)
end
