  json.id task['id']
  json.task_number task['task_number']
  json.task_request_type_code WebserviceResources::Converter.cc_id_to_code(WebserviceResources::TaskRequestType, task['task_request_type_id'])
  json.subject task['name']
  json.description task['description']
  json.due_at task['due_at']|| "open"
  json.follow_up_at task['follow_up_at']
  json.status "new" #always will be new
  json.assigned_to task['task_assigned_user_id'] || "unassigned" #always NONE unassigned 