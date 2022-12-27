class BloodPressureObservation
  attr_accessor :systolic_observation, :diastolic_observation, :id, :code, :unit, :patient, :effective_start_date, :encounter, :business_entity, :provider, :code_display, :created_at

  def initialize(observations)
  	@systolic_observation = OpenStruct.new(observations.select{|a| a['code'] == ObservationCode::SYSTOLIC}.first)
  	@diastolic_observation = OpenStruct.new(observations.select{|a| a['code'] == ObservationCode::DIASTOLIC}.first)
  	@id = "#{@systolic_observation.id}-#{@diastolic_observation.id}-#{ObservationType::BLOOD_PRESSURE}"
    @code = ObservationCode::BLOOD_PRESSURE
    @unit = "MilliMeters of Mercury [Blood Pressure Unit]"
    @patient = OpenStruct.new(systolic_observation.patient)
    @provider =  OpenStruct.new(systolic_observation.provider)
    @business_entity = OpenStruct.new(systolic_observation.business_entity)
    @encounter = systolic_observation.encounter
    @effective_start_date = systolic_observation.effective_start_date
    @code_display = 'Blood Pressure'
    @created_at = @systolic_observation.created_at
  end
end