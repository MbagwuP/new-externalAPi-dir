
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
    "LABORATORY_TESTS",
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
    @date = params[:date]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @sections = Array.wrap(params[:sections])
    @patient_ids = [*params[:patient_ids], *params[:patient_guids], *params[:patient_id], *params[:patient_guid]]
    @token = token
    @business_entity_guid = business_entity_guid
  end

  def call
    before_validate
    validate!
    return if errors.any?
    build_params
  end

  private

  attr_reader :date, :start_date, :end_date, :sections, :patient_ids, :token,
    :business_entity_guid

  def before_validate
    sections = Array.wrap(sections).map(&:upcase) if sections
  end

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
      params[:end_date] = [
        Date.parse(end_date),
        Date.parse(start_date) + 30.days
      ].min.to_s
    end
    params
  end

  def single_date?
    !!@date
  end

  def date_range?
    !!@start_date
  end

  def validate_date_params
    if !valid_date_parameters?
      errors.add(:base,
        "Invalid date parameters. Either pass a single 'date' or pass a "\
        "'start_date' and 'end_date'."
      )
    elsif single_date?
      errors.add(:date, "Date must be YYYY-MM-DD") unless valid_date?(date)
    elsif date_range?
      errors.add(:start_date, "Date must be YYYY-MM-DD") unless valid_date?(start_date)
      errors.add(:end_date, "Date must be YYYY-MM-DD") if end_date && !valid_date?(end_date)
      if Date.parse(@start_date) > Date.parse(@end_date)
        errors.add(:date, "Start date must be before end date")
      end
    end
  end

  def any_date_params?
    !!@date || !!@start_date || !!@end_date
  end

  def valid_date_parameters?
    (!!@date && !@start_date && !@end_date) || 
      (!!@start_date && !!@end_date && !@date )
  end

  def valid_date?(date)
    !!date.match(DATE_WITH_DASHES_REGEX)
  end

end
