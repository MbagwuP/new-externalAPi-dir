json.array! @resp do |rt|
  json.recall_type do

    json.id rt['recall_type']['id']
    json.description rt['recall_type']['description']
    json.name rt['recall_type']['name']
    json.created_at rt['recall_type']['created_at']
    json.updated_at rt['recall_type']['updated_at']

  end
end
