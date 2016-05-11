json.id recall['recall']['guid']
json.comments recall['recall']['comments']
json.recall_at recall['recall']['recall_at']

json.recall_type do
  json.id recall['recall']['recall_type']['id']
  json.name recall['recall']['recall_type']['name']
  json.description recall['recall']['recall_type']['description']
end

json.recall_status do
  json.code RecallStatus.parse_name_to_code(recall['recall']['recall_status']['name'])
  json.name recall['recall']['recall_status']['name']
end

json.patient do
  json.id recall['recall']['patient']['external_id']
  json.preferred_communication_method communication_methods.invert[recall['recall']['patient']['preferred_communication_method_id']]
end