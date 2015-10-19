json.array! @resp do |rec|
  json.recall do

    json.id rec['recall']['id']
    json.comments rec['recall']['comments']
    json.patient_id rec['recall']['patient']['external_id']
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

  end
end
