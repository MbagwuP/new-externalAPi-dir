class AppointmentAvailabilitySearchCriteria
  
  attr_reader :query_params
  
  class InvalidParameterError < StandardError; end
  
  REQUIRED_PARAMS = ['start_date', 'visit_reason_id', 'location_ids', 'resource_ids', 'token', 'business_entity_id']
  
  OPTIONAL_PARAMS = [
                      'end_date', # defaults to start_date
                      'meridian', # defaults to afternoon:true and morning:true
                      'dow', # defaults to '0111110' (weekdays)
                      'duration', # defaults to nil; back-end has handling so that it will use the visit_reason_id's default duration
                      'is_any_resource',
                      'is_any_location',
                      'is_location_read_only'
                    ]
                    
  VALID_PARAMS = REQUIRED_PARAMS + OPTIONAL_PARAMS
  
  DAYS_OF_WEEK = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
  
  DEFAULT_DOW = "0111110"
    
  def initialize(params)
    validate_params(params)
    @valid_params = params.select{ |k, v| VALID_PARAMS.include?(k) }.with_indifferent_access
    build_required_query_params
    build_optional_query_params
  end
  
  private
  
  attr_reader :valid_params
    
  def build_required_query_params
    @query_params = {
      date_range_start: valid_params[:start_date],
      morning: meridian_matches?(valid_params, 'am'),
      afternoon: meridian_matches?(valid_params, 'pm'),
      business_entity_id: valid_params[:business_entity_id],
      original_business_entity_id: valid_params[:business_entity_id].to_i,
      sequential: true,
      token: valid_params[:token],
      search_criterias: [
        {
          nature_of_visit_id: valid_params[:visit_reason_id].to_i,
          resource_ids: resource_ids(valid_params).map(&:to_i),
          location_ids: location_ids(valid_params).map(&:to_i)
        }
      ]
    }.merge(dow_to_wday_hash(valid_params))
  end
  
  def build_optional_query_params
    @query_params.merge!(date_range_end: valid_params[:end_date]) if valid_params[:end_date]
    @query_params[:search_criterias].first.merge!(duration: valid_params[:duration].to_i) if valid_params[:duration]
    @query_params[:search_criterias].first.merge!(is_any_resource: valid_params[:is_any_resource]) if valid_params[:is_any_resource]
    @query_params[:search_criterias].first.merge!(is_any_location: valid_params[:is_any_location]) if valid_params[:is_any_location]
    @query_params[:search_criterias].first.merge!(is_location_read_only: valid_params[:is_location_read_only]) if valid_params[:is_location_read_only]
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
    validate_meridian(params)
    validate_duration(params)
    validate_dow(params)
    validate_dates(params)
    validate_integers(params)
    validate_arrs_of_integers(params)
  end
  
  def all_required_params(params)
    error_msg = if (params.keys & REQUIRED_PARAMS).sort != REQUIRED_PARAMS.sort
      'Missing Required Parameter'
    end
    raise InvalidParameterError, error(error_msg) if error_msg
  end
  
  def validate_meridian(params)
    error_msg = if !['am', 'pm', nil].include?(params['meridian'].try(:downcase))
      'Invalid Meridian'
    end
    raise InvalidParameterError, error(error_msg) if error_msg
  end
  
  def validate_duration(params)
    error_msg = if params['duration'] && params['duration'].respond_to?(:to_i) && params['duration'].to_i <= 0
      'Invalid Duration'
    end
    raise InvalidParameterError, error(error_msg) if error_msg
  end
  
  def validate_dow(params)
    error_msg = if dow(params).length != 7
      'Invalid Length For Days of Week'
    elsif dow(params).chars.sort & ['0', '1'] != dow(params).chars.uniq.sort
      'Invalid Characters in Days of Week'
    end
    raise InvalidParameterError, error(error_msg) if error_msg
  end
  
  def validate_dates(params)
    error = ParamsValidator.new(params, :end_date_is_before_start_date, :invalid_date_passed, :blank_date_field_passed, :date_filter_range_too_long).error
    raise InvalidParameterError, error if error
  end
  
  def validate_integers(params)
    keys = ['visit_reason_id', 'duration'] & params.keys
    keys.each do |k|
      if params[k].to_i <= 0 || params[k].to_i.to_s != params[k]
        raise InvalidParameterError, "Invalid #{k.split('_').map(&:capitalize).join(' ')}"
      end
    end
  end
  
  def validate_arrs_of_integers(params)
    keys = ['resource_ids', 'location_ids'] & params.keys
    keys.each do |k|
      params[k].gsub(' ', '').split(',').each do |x|
        if x.to_i <= 0 || x.to_i.to_s != x
          raise InvalidParameterError, "Invalid #{k.split('_').map(&:capitalize).join(' ')}"
        end
      end
    end
  end
  
  def error(msg)
    '{"error":"' + msg + '"}' if msg
  end
  
end