class ApiService < Sinatra::Base

  get '/v2/patients/:patient_id/tasks' do
    PatientTaskType = 10
    
    url = webservices_uri "patient_tasks.json", {token: escaped_oauth_token, patient_id: params[:patient_id], task_type_id: PatientTaskType , filter: true}
    resp = rescue_service_call 'List Patient Tasks',true do
      RestClient.get(url, :api_key => APP_API_KEY)
    end
    @tasks = JSON.parse(resp.body)
    status HTTP_OK
    jbuilder :list_tasks
  end
  
  post '/v2/patients/:patient_id/tasks' do
    body = get_request_JSON
    api_svc_halt HTTP_BAD_REQUEST, '{error: task_request_type_code is required.}' if body.try(:[],"task").try(:[],"task_request_type_code").nil?
    begin 
      @task = TaskResource.create(body,escaped_oauth_token,params[:patient_id])
    rescue => e
      begin
        exception = e.message
        api_svc_halt e.http_code, exception
      rescue 
        api_svc_halt HTTP_INTERNAL_ERROR, exception
      end
    end 
    @task['task']['follow_up_at'] = Date.parse(@task['task']['follow_up_at']).to_s if @task['task']['follow_up_at']
    @task['task']['due_at'] = Date.parse(@task['task']['due_at']).to_s if @task['task']['due_at']
    status HTTP_CREATED
    jbuilder :show_task
  end 
  
end