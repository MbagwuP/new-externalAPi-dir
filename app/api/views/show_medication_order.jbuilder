json.medication do
  json.partial! :medication, medication: OpenStruct.new(@medication)
end