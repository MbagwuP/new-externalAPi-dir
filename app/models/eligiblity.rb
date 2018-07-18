class EligibilityResource
  extend Client::Webservices
  
  def self.create(request,appointment_id,token)
    payload = Eligibility.new(request, appointment_id).add_root_key
    url = build_eligibility_url(nil,nil,token)
    make_request('Create Manual Eligibility Request',"post",url,payload)
  end
  
  def self.build_eligibility_url(patient_id=nil, request_id=nil,token)
    return webservices_uri "eligibility_request/create_manual", token: token if patient_id.nil?
    if (current_internal_request_header)
      webservices_uri(eligibility_path(patient_id, request_id))
    else
      webservices_uri(eligibility_path(patient_id, request_id), token: token)
    end
  end

  def self.eligibility_path(patient_id, request_id=nil)
    path = "patients/#{patient_id}/eligibility_request"
    path << "/#{request_id}" if request_id
    path
  end

end
  
class Eligibility
  
  def initialize(options,appointment_id)
    @appointment_id = appointment_id
    @eligibility_outcome_id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::EligibilityOutcome, options['outcome'])
    @eligibility_method_id = check_method_value(options['method'])
    @eligibility_origin_id = AppointmentOrigin
    @eligibility_date = options.delete('date_of_service')
    @co_payment = options['co_payment']
    @deductible = options['deductible']
    @outstanding_deductible = options['outstanding_deductible']
    @co_insurance = options['co_insurance']
    @comments = options['comments']
  end
  
  AppointmentOrigin = 1
  
  def check_method_value(method)
    raise Error::InvalidRequestError.new("'Auto' method can not be used for a manual eligibility request") if method.downcase == "au"
    WebserviceResources::Converter.code_to_cc_id(WebserviceResources::EligibilityMethod, method)
  end
  
  def add_root_key
    payload = {}
    payload['request'] = self.as_json
    payload
  end
   
end