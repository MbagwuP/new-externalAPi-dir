class AppointmentAvailability
  
  # Problems:
  # how is is_any_location being used? -- not used
  # how is is_any_resource being used? -- not used
  # how is is_location_read_only being used? -- not used
  # how do I get duration? - will be handled by back-end, if not provided

  # TODO:
  # use meridian instead of tod -- check
  # add errors for invalid dow
  # rename visit_reason_id to visit_reason_id
  # make location_ids optional
  # rename resource_ids to resource_ids
  # rename location_ids to location_ids
  # validate date range
  
  REQUIRED_PARAMS = ['start_date', 'visit_reason_id', 'location_ids', 'resource_ids', 'business_entity_id', 'token']
  
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
  
  def initialize(params)
    @usable_params = valid_params(params).with_indifferent_access
    if @usable_params
      @request_body = {}
    else
      raise ArgumentError
    end
  end
  
  def structure_request_body
    @request_body['date_range_start'] = @usable_params['start_date']
    @request_body['date_range_end'] = @usable_params['end_date']
    @request_body['morning'] = meridian_matches?('am')
    @request_body['afternoon'] = meridian_matches?('pm')
    @request_body['business_entity_id'] = @usable_params['business_entity_id']
    @request_body['original_business_entity_id'] = @usable_params['business_entity_id']
    @request_body.merge!(dow_to_wday_hash)
    @request_body['sequential'] = true
    @request_body['search_criterias'] = [{
      'nature_of_visit_id' => @usable_params['visit_reason_id'],
      'resource_ids' => @usable_params['resource_ids'],
      'location_ids' => @usable_params['location_ids'],
      'is_any_resource' => @usable_params['is_any_resource'] || false,
      'is_any_location' => @usable_params['is_any_location'] || false,
      'is_location_read_only' => @usable_params['is_location_read_only'] || false
      }]
    @request_body['search_criterias'].first['duration'] = @usable_params['duration'] if @usable_params['duration']
    @request_body['token'] = @usable_params['token']
    @request_body
  end
  
###################### structure_request_body Helpers ##########################
  
  # def meridian_is_morning?
  #   !@usable_params['meridian'] || @usable_params['meridian'].any? { |m| m == 'am' }
  # end
  # 
  # def meridian_is_afternoon?
  #   !@usable_params['meridian'] || @usable_params['meridian'].any? { |m| m == 'pm' }
  # end
  
  def meridian_matches?(meridian)
    !@usable_params['meridian'] || @usable_params['meridian'].any? { |m| m == meridian }

  end
  
  def dow_to_wday_hash
    @usable_params['dow'].chars.each_with_object({}).with_index do |(bd, wday_hsh), idx| 
      wday_hsh[DAYS_OF_WEEK[idx]] = (bd == "1")
    end
  end
  
#################### Validations && Validation Helpers #########################
  
  def valid_params(params)
    if all_params_valid?(params)
      clean_params(params)
    else
      false
    end
  end
  
  def all_params_valid?(params)
    all_required_params?(params) &&
    valid_dow?(params) &&
    valid_meridian?(params) &&
    valid_duration?(params) &&
    !ParamsValidator.new(params, :end_date_is_before_start_date, :invalid_date_passed, :blank_date_field_passed, :date_filter_range_too_long).error
  end
  
  def all_required_params?(params)
    (params.keys & REQUIRED_PARAMS).sort == REQUIRED_PARAMS.sort
  end
  
  def valid_meridian?(params)
    ['am', 'pm', nil].include?(params['meridian'].try(:downcase))
  end
  
  def valid_duration?(params)
    params['duration'].nil? || (params['duration'].respond_to?(:to_i) && params['duration'].to_i > 0)
  end
  
  def valid_dow?(params)
    dow(params).length == 7 && dow(params).chars.sort & ['0', '1'] == dow(params).chars.uniq.sort
  end
  
  def dow(params)
    params['dow'] || "0111110"
  end
  
############################# Params Helpers ###################################
  
  def clean_params(params)
    result = params.select{ |k, v| VALID_PARAMS.include?(k) }
    result['dow'] = dow(params)
    result['resource_ids'] = result['resource_ids'].split(',').map(&:strip)
    result['location_ids'] = result['location_ids'].split(',').map(&:strip)
    result['start_date'] = Time.parse(result['start_date'])
    result['end_date'] = Time.parse(result['end_date']) if result['end_date']
    result['meridian'] = result['meridian'].downcase.split(',').map(&:strip) if result['meridian']
    result
  end
  
end