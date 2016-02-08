require 'spec_helper'
APP_API_KEY = "a"
describe RecallStatus do 
  it 'parses and caches webservices recall statuses ' do

    stubbed_signed_request = stub
    CCAuth::InternalService::Request.stub(:sign!).and_return(stubbed_signed_request)
    stubbed_signed_request.stub(:execute).and_return("[{\"recall_status\":{\"code\":\"PND\",\"created_at\":\"2011-10-10T22:58:22-04:00\",\"created_by\":1,\"description\":\"Pending\",\"id\":1,\"name\":\"Pending\",\"sort_code\":1,\"status\":\"A\",\"updated_at\":\"2011-10-10T22:58:22-04:00\",\"updated_by\":1}},{\"recall_status\":{\"code\":\"ASG\",\"created_at\":\"2011-10-10T22:58:22-04:00\",\"created_by\":1,\"description\":\"Assigned\",\"id\":2,\"name\":\"Assigned\",\"sort_code\":1,\"status\":\"A\",\"updated_at\":\"2011-10-10T22:58:22-04:00\",\"updated_by\":1}},{\"recall_status\":{\"code\":\"CMP\",\"created_at\":\"2011-10-10T22:58:22-04:00\",\"created_by\":1,\"description\":\"Completed\",\"id\":3,\"name\":\"Completed\",\"sort_code\":1,\"status\":\"A\",\"updated_at\":\"2011-10-10T22:58:22-04:00\",\"updated_by\":1}},{\"recall_status\":{\"code\":\"AF\",\"created_at\":\"2016-01-20T15:28:42-05:00\",\"created_by\":1,\"description\":null,\"id\":4,\"name\":\"ATTEMPT FAILED\",\"sort_code\":null,\"status\":\"A\",\"updated_at\":\"2016-01-20T15:28:42-05:00\",\"updated_by\":1}}]")

    expect(RecallStatus.parse_to_webservices("pending")).to eq 1
  end
end