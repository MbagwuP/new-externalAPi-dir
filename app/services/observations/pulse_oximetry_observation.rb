class PulseOximetryObservation
  attr_accessor :oxygen_saturation, :inhaled_oxygen_concentration, :id, :code, :unit, :patient, :effective_start_date, :encounter, :business_entity, :provider, :code_display, :code_display_oximetry, :created_at

  def initialize(observations)
  	@oxygen_saturation = OpenStruct.new(observations.select{|a| a['code'] == ObservationCode::OXYGEN_SATURATION}.first)
  	@inhaled_oxygen_concentration = OpenStruct.new(observations.select{|a| a['code'] == ObservationCode::INHALED_OXYGEN_CONCENTRATION}.first)
    @id = "#{@oxygen_saturation.id}-#{@inhaled_oxygen_concentration.id}-#{ObservationType::PULSE_OXIMETRY}"
    @code = ObservationCode::PULSE_OXIMETRY
    @unit = "%"
    @patient = OpenStruct.new(oxygen_saturation.patient)
    @provider =  OpenStruct.new(oxygen_saturation.provider)
    @business_entity = OpenStruct.new(oxygen_saturation.business_entity)
    @encounter = oxygen_saturation.encounter
    @effective_start_date = oxygen_saturation.effective_start_date
    @code_display = 'Oxygen saturation in Arterial blood'
    @code_display_oximetry = 'Oxygen saturation in Arterial blood by Pulse oximetry'
    @created_at = @oxygen_saturation.created_at
  end
end