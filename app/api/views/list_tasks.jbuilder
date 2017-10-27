json.tasks @tasks['tasks'] do |task|
  json.id task['id']
  json.task_number task['task_number']
  json.subject task['name']
  json.type task['request_type']
  json.description task['description']
  json.due_at task['due_at']
  json.status task['task_status']
  json.action task['task_action']
  json.priority task['task_priority']
  json.assigned_to task['task_assigned_user']
  json.comments task['comments']
end