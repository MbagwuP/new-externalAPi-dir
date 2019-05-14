class ClinicalFormResource
  extend Client::Webservices

  def self.create(request,current_business_entity,token)
    payload = ClinicalForm.new(request, current_business_entity)
    url = webservices_uri("clinical/patients/#{payload.patient_id}/clinical_forms",token: token)
    if payload.valid?
      make_request('Merge Clinical Findings',"post",url,payload.as_json)
    else
      raise Error::InvalidRequestError.new(payload.error_messages)
    end
  end
  
end

class ClinicalForm 
  
  attr_accessor(:patient_id)
  
  REQUIRED_FIELDS = ["patient_id","findings","xml"]
  
  def initialize(options,business_entity_id)
    @errors = {}
    @patient_id = options["patient_id"]
    @appointment_id = options["appointment_id"]
    @business_entity_id = business_entity_id
    @findings = Array.wrap(options["findings"])
    @xml =  Array.wrap(options["xml"])
    @uuid = options["uuid"] || nil
    validate
  end
  
  def valid?
    @errors.empty?
  end
  
  def error_messages
    msg = ""
    @errors.each do |k,v|
      msg << "#{k}: #{v}"
    end
  end
  
  def validate
    form = self.instance_values
    REQUIRED_FIELDS.each do |param|
      @errors[param] = "Required param." unless form[param].present?
    end
  end 
   
end 