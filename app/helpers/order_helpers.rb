class ApiService < Sinatra::Base

  def intent(patient_reported)
    return nil if patient_reported
    
    "order"
  end

  def reported_reference(patient_reported)
    patient_reported ? "Patient" : "Practitioner"
  end
end