class ChargeResource < Request

  def self.create(request,patient_id,token,current_business_entity)
    payload = ChargeRequest.new(request, patient_id)
    url = webservices_uri "charges/#{patient_id}/business_entity/#{current_business_entity}/create.json", {token: token}
    if payload.valid?
      make_request('Create Charge Request',"post",url,payload.as_json)
    else
      raise InvalidRequestError.new(payload.error_messages)
    end
  end
end
  
class ChargeRequest < Request 
 
  REQUIRED_FIELDS = ["start_time","end_time", "units","procedure_code","diagnosis1_code"]
  
  def initialize(options,patient_id)
    @errors = {}
    @charge = options['charge']
    @charge['start_time'] = validate_date("start_time",@charge['start_time']) if @charge['start_time'].present?
    @charge['end_time'] = validate_date("end_time", @charge['end_time']) if @charge['end_time'].present?
    @charge['date_of_service'] = date_of_service(@charge['start_time']) 
    @patient_id = patient_id
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
    REQUIRED_FIELDS.each do |param|
      @errors[param] = "Required param." unless @charge[param].present?
    end
    @errors["start_time/end_time"] = "end_time can't be before start_time" if (@charge['start_time'].present? && @charge['end_time'].present?) && (@charge['start_time'] > @charge['end_time'])
    validate_icd_indicator(@charge['icd_indicator'])
  end
  
  def validate_icd_indicator(icd_indicator)
    if icd_indicator.blank?
      indicator_value = 10
    elsif ![9, 10].include? icd_indicator.to_i
      @errors["icd_indicator"] = "icd_indicator must be \'9\' or \'10\'"
    end
  end
  
  def date_of_service(start_time)
    start_time
  end
  
  def validate_date(param,date)
    #ISO 8601 accepted format- YYYY-MM-DDTHH:MM (UTC)
    begin
      date = DateTime.iso8601(date)
      @errors[param] = "#{param} can't be in the future" if date >= date.tomorrow
      date
    rescue ArgumentError => e 
      @errors[param] = e.message
    end
  end
  
end