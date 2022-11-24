medication = OpenStruct.new(@medication)

json.medication do
  json.partial! :medication, medication: medication
end
