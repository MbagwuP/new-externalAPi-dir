class SimpleChargeResource < ChargeResource
  def self.create(request,patient_id,token)
    payload = SimpleCharge.new(request, patient_id)
    url = webservices_uri "simple_charges.json", {token: token}
    if payload.valid?
      make_request('Create Simple Charge Request',"post",url,payload.as_json)
    else
      raise Error::InvalidRequestError.new(payload.error_messages)
    end
  end
end

class SimpleCharge < Charge

  REQUIRED_FIELDS = ["simple_charge_type"]

  def initialize(options,patient_id)
    @errors = {}
    @simple_charge = options["simple_charge"]
    @debit = options["debit"]
    @patient_id = patient_id
    validate
  end

    def validate
      REQUIRED_FIELDS.each do |param|
        @errors[param] = "Required param." unless @simple_charge[param].present?
      end
    end
end
