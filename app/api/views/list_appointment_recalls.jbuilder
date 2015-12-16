json.array! @resp do |rec|
  json.recall do

    json.id rec['recall']['guid']
    json.comments rec['recall']['comments']
    json.recall_at rec['recall']['recall_at']

    json.recall_type do
      json.id rec['recall']['recall_type']['id']
      json.name rec['recall']['recall_type']['name']
      json.description rec['recall']['recall_type']['description']
    end

    json.recall_status do
      json.id rec['recall']['recall_status']['id']
      json.name rec['recall']['recall_status']['name']
      json.code rec['recall']['recall_status']['code']
      json.description rec['recall']['recall_status']['description']
    end

    json.patient do
      json.id rec['recall']['patient']['external_id']
      json.preferred_communication_method communication_methods.invert[rec['recall']['patient']['preferred_communication_method_id']]
    end

  end
end
