class TaskResource
  extend Client::Webservices
  
  def self.create(options,token,patient_id)
    payload = Task.new(options,patient_id)
    url = webservices_uri("patient_tasks.json", {token: token})
    if payload.valid?
      make_request('Create Task',"post",url,payload.as_json)
    else
      raise Error::InvalidRequestError.new(payload.error_messages)
    end
  end
end
  
class Task
  
  def initialize(options,patient_id)
    @errors = []
    @task = options["task"]
    @task["task_request_type_id"] = convert_task_request_code_to_id(options["task"].delete("task_request_type_code"))
    @task["name"] = convert_task_request_id_to_name(@task["task_request_type_id"])
    @task["description"] = options["task"]["description"] || @task["name"]
    @task["due_at"] = convert_empty_string_to_nil(options["task"]["due_at"])
    @task["follow_up_at"] = convert_empty_string_to_nil(options["task"]["follow_up_at"])
    @task["assigned_user_id"] = convert_empty_string_to_nil(options["task"]["assigned_user_id"])
    @patient_id = patient_id 
    validate
  end
  
  def convert_empty_string_to_nil(value)
    value.blank? ? nil : value
  end 
  
  def convert_task_request_code_to_id(code)
    converter = WebserviceResources::Converter 
    converter.code_to_cc_id(WebserviceResources::TaskRequestType, code)
  end
  
  def convert_task_request_id_to_name(id)
    converter = WebserviceResources::Converter 
    converter.id_to_name(WebserviceResources::TaskRequestType, id)
  end
  
  def date_in_the_future?(date)
    return true if date.nil?
    Date.parse(date) >= Date.today
  rescue => e 
    @errors << e.message
  end
  
  def valid?
    @errors.empty?
  end
  
  def validate 
    @errors << "Due date must be in the future" unless date_in_the_future?(@task["due_date"]) 
    @errors << "Follow up date must be in the future" unless date_in_the_future?(@task["follow_up_at"])
  end
  
  def error_messages
    @errors
  end
  
end 