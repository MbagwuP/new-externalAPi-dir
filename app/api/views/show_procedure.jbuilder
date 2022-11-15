procedure = OpenStruct.new(@procedure)
json.procedure do
  json.partial! :procedure, procedure: OpenStruct.new(@procedure)
end