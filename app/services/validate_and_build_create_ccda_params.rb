
class ValidateAndBuildCreateCcdaParams
  prepend SimpleCommand

  DATE_WITH_DASHES_REGEX = /[12]\d{3}-(1[012]|0[123456789])-([12]\d|0[123456789]|3[01])/
  VALID_SECTIONS = [
    "PATIENT_NAME",
    "SEX",
    "DATE_OF_BIRTH",
    "RACE",
    "ETHNICITY",
    "PREFERRED_LANGUAGE",
    "SMOKING_STATUS",
    "PROBLEMS",
    "MEDICATIONS",
    "MEDICATION_ALLERGIES",
    "LABORATORY_RESULTS",
    "VITAL_SIGNS",
    "PROCEDURES",
    "CARE_TEAM_MEMBERS",
    "IMMUNIZATIONS",
    "UNIQUE_DEVICE_IDENTIFIERS",
    "PLAN_OF_TREATMENT",
    "GOALS",
    "HEALTH_CONCERNS",
    "REASON_FOR_REFERRAL",
    "ASSESSMENT"
  ]

  def initialize(params, token:, business_entity_guid:)
    @sections = (params[:sections] || []).map(&:upcase)
    @patient_ids = [*params[:patient_ids], *params[:patient_guids], *params[:patient_id], *params[:patient_guid]]
    
    @token = token
    @business_entity_guid = business_entity_guid
    @scoped_request =  params[:scoped_request]
    
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @date = params[:date]
    @date = Date.today.to_s if @scoped_request && !any_date_params?
  end

  def call
    validate!
    return if errors.any?
    build_params
  end

  private

  attr_reader :date, :start_date, :end_date, :sections, :patient_ids, :token,
    :business_entity_guid

  # Intentionally didn't use ParamsValidator (app/models/params_validator.rb)
  # here due to inflexibility in capturing multiple errors and to use a more
  # precise date regex.
  # In the future, it might be worthwhile to incoporate multiple errors into
  # that class using ActiveRecord Validations or SimpleCommand.
  def validate!
    validate_date_params if any_date_params?
    invalid_section = sections && sections.any? do |section|
      VALID_SECTIONS.exclude?(section.upcase)
    end
    errors.add(:sections, "Invalid section") if invalid_section
  end

  def build_params
    params = {
      token: token,
      business_entity_guid: business_entity_guid
    }

    params[:patient_guids] = patient_ids if patient_ids
    params[:sections] = sections if sections.any?

    if single_date?
      params[:start_date] = date
      params[:end_date] = date
    elsif date_range?
      params[:start_date] = start_date
      params[:end_date] = end_date
    end
    params
  end

  def single_date?
    !!@date
  end

  def date_range?
    !!@start_date && !!@end_date
  end

  def validate_date_params
    if !valid_date_parameters?
      errors.add(:base,
        "Invalid date parameters. Either pass a single 'date' or pass a "\
        "'start_date' and 'end_date'.")
      return 
    end
    
    if single_date? 
      valid_date?(date) ? Date.parse(date) : invalid_date_error(:date)
    end
     
    if date_range? 
      invalid_date_error(:start_date) unless valid_date?(start_date)
      invalid_date_error(:end_date) unless valid_date?(end_date)
      
      return if errors.any?
      
      start_date_parsed = Date.parse(start_date)
      end_date_parsed = Date.parse(end_date)
      no_of_days  = (end_date_parsed - start_date_parsed).to_i
      
      errors.add(:end_date, "Date range can't be more than 30 days") if @scoped_request && (no_of_days > 30)
      errors.add(:start_date, "Start date must be before end date") if no_of_days < 0
    end
  rescue => e 
    errors.add(:base, "Invalid Date Param: #{e.message}")
  end

  def any_date_params?
    !!@date || !!@start_date || !!@end_date
  end

  def valid_date_parameters?
    (!!@date && !@start_date && !@end_date) || 
      (!!@start_date && !!@end_date && !@date )
  end
  
  def invalid_date_error(param)
    date_type = param.to_s.gsub("_"," ")
    errors.add(param, "Invalid #{date_type}")
  end 

  def valid_date?(date)
    !!date.match(DATE_WITH_DASHES_REGEX) && Date.parse(date)
  rescue
    false
  end

end
