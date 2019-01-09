class AppointmentAvailabilitySearchCriteria
  
  attr_reader :query_params
  
  class InvalidParameterError < StandardError; end
  
  REQUIRED_PARAMS = ['start_date', 'visit_reason_id', 'location_ids', 'resource_ids', 'token', 'business_entity_id'].freeze
  
  OPTIONAL_PARAMS = [
                      'end_date', # defaults to start_date
                      'meridian', # defaults to afternoon:true and morning:true
                      'dow', # defaults to '0111110' (weekdays)
                      'duration' # defaults to nil; back-end has handling so that it will use the visit_reason_id's default duration
                    ].freeze
                    
  VALID_PARAMS = (REQUIRED_PARAMS + OPTIONAL_PARAMS).freeze
  VALID_MERIDIANS = ['am', 'pm', nil].freeze
  VALID_DOW_CHARS = ['0', '1'].freeze
  
  DAYS_OF_WEEK = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'].freeze
  
  DEFAULT_DOW = "0111110".freeze
  
  INTEGER_REGEX = /^[0-9]+$/.freeze
    
  def initialize(params)
    validate_params(params)
    valid_params = params.select{ |k, v| VALID_PARAMS.include?(k) }.with_indifferent_access
    @query_params = build_query_params(valid_params)
  end
  
  private
  
  def build_query_params(params)
    qp = build_required_query_params(params)
    qp[:search_criterias] = build_search_criterias(params)
    qp[:date_range_end] = params[:end_date] if params[:end_date]
    qp
  end
  
  def build_required_query_params(params)
    {
      date_range_start: params[:start_date],
      morning: meridian_matches?(params, 'am'),
      afternoon: meridian_matches?(params, 'pm'),
      business_entity_id: params[:business_entity_id],
      original_business_entity_id: params[:business_entity_id],
      sequential: true,
      token: params[:token]
    }.merge(dow_to_wday_hash(params))
  end
  
  def build_search_criterias(params)
    scp =
      {
        nature_of_visit_id: params[:visit_reason_id].to_i,
        resource_ids: resource_ids(params).map(&:to_i),
        location_ids: location_ids(params).map(&:to_i)
      }
    scp[:duration] = params[:duration].to_i if params[:duration]
    [scp]
  end
  
###################### Build Query Params Helpers ##############################
      
  def meridian_matches?(params, meridian)
    params['meridian'].blank? || params['meridian'].split(',').map(&:strip).any? { |m| m.downcase == meridian.downcase }
  end
  
  def dow_to_wday_hash(params)
    dow(params).chars.each_with_object({}).with_index do |(bd, wday_hsh), idx| 
      wday_hsh[DAYS_OF_WEEK[idx].to_sym] = (bd == "1")
    end
  end
  
  def resource_ids(params)
    params[:resource_ids].split(',').map(&:strip) if params[:resource_ids]
  end
  
  def location_ids(params)
    params[:location_ids].split(',').map(&:strip) if params[:location_ids]
  end
  
  def dow(params)
    params['dow'] || DEFAULT_DOW
  end
  
#################### Validations && Validation Helpers #########################
    
  def validate_params(params)
    all_required_params(params)
    validate_meridian(params['meridian'])
    validate_duration(params['duration'])
    validate_dow(dow(params))
    validate_dates(params.slice('start_date', 'end_date'))
    validate_integers(params.slice('visit_reason_id', 'duration', 'resource_ids', 'location_ids'))
  end
  
  def all_required_params(params)
    error_msg = if (params.keys & REQUIRED_PARAMS).sort != REQUIRED_PARAMS.sort
      'Missing Required Parameter'
    end
    raise InvalidParameterError, error_msg if error_msg
  end
  
  def validate_meridian(meridian)
    error_msg = if !VALID_MERIDIANS.include?(meridian.try :downcase)
      'Invalid Meridian'
    end
    raise InvalidParameterError, error_msg if error_msg
  end
  
  def validate_duration(duration)
    error_msg = if duration && duration.respond_to?(:to_i) && duration.to_i <= 0
      'Invalid Duration'
    end
    raise InvalidParameterError, error_msg if error_msg
  end
  
  def validate_dow(dow)
    error_msg = if dow.length != 7
      'Invalid Length For Days of Week'
    elsif dow.chars.sort & VALID_DOW_CHARS != dow.chars.uniq.sort
      'Invalid Characters in Days of Week'
    end
    raise InvalidParameterError, error_msg if error_msg
  end
  
  def validate_dates(dates_hash)
    error = ParamsValidator.new(dates_hash, :end_date_is_before_start_date, :invalid_date_passed, :blank_date_field_passed, :date_filter_range_too_long).error
    pretty_error = JSON.parse(error)['error'].gsub('_', ' ').split(' ').map(&:capitalize).join(' ') if error
    raise InvalidParameterError, pretty_error if error
  end
  
  # clean these two methods up so that they do only what their defs say
  def validate_integers(ints_hash)
    invalid_ints = ints_hash.select do |k, v|
      v.split(',').any? do |int|
        !INTEGER_REGEX.match(int)
      end
    end
    error_msg = "Invalid #{invalid_ints.first.keys.first.split('_').map(&:capitalize).join(' ')}" if !invalid_ints.empty?
    raise InvalidParameterError, error_msg if error_msg
  end
    
end