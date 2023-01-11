json.resource_count @all_resource_count
json.fhir_resource do
  json.array! @total_counts.each do |obj|
      json.fhir_resource obj
  end
end

