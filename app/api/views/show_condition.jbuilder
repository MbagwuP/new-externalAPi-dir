json.condition do
  json.partial! :condition, condition: OpenStruct.new(@condition)
end