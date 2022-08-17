class ParamsValidator

  def initialize params, *args
    @params      = params.with_indifferent_access
    @validations = args
  end

  def invalid_date_passed
    begin
    error = 'Invalid Date format for start and/or end date parameter. Valid Date format is YYYY-MM-DD or YYYYMMDD'
    if @params[:start_date].present?
      Date.parse(@params[:start_date])
      return error if date_format_invalid?(@params[:start_date])
    end
    if @params[:end_date].present?
      Date.parse(@params[:end_date])
      return error if date_format_invalid?(@params[:end_date])
    end
    if @params[:created_at_from].present?
      Date.parse(@params[:created_at_from])
      return error if date_format_invalid?(@params[:created_at_from])
    end
    if @params[:created_at_to].present?
      Date.parse(@params[:created_at_to])
      return error if date_format_invalid?(@params[:created_at_to])
    end
    rescue ArgumentError
      'Invalid Date. The valid date format is YYYY-MM-DD or YYYYMMDD'
    end
  end

  def blank_date_field_passed
    if (@params[:start_date].blank?) || (@params[:end_date].blank?)
      'Date filtering fields cannot be blank.'
    end
  end

  def missing_one_date_filter_field
    if [@params[:start_date], @params[:end_date]].compact.length == 1
      'Both start_date and end_date are required for date filtering.'
    end
  end

  def missing_end_date_filter_field
    if @params[:end_date].blank?
      'end_date is required for date filtering.'
    end
  end

  def date_filter_range_too_long
    return nil if !@params[:end_date] || !@params[:start_date]

    if (Date.parse(@params[:end_date]) - Date.parse(@params[:start_date])).to_i > 93
      'Date ranges may not exceed 93 days in length.'
    end
  end

  def end_date_is_before_start_date
    return nil if !@params[:end_date] || !@params[:start_date]

    if Date.parse(@params[:end_date]) < Date.parse(@params[:start_date])
      'end_date may not precede start_date.'
    end
  end

  def created_at_from_is_after_created_at_to
    return nil if !@params[:created_at_from] || !@params[:created_at_to]

    if Date.parse(@params[:created_at_from]) > Date.parse(@params[:created_at_to])
      "created_at_from can't be after created_at_to."
    end
  end

  def future_date
    return nil if @params[:created_at_from].nil? || @params[:created_at_to].nil?
    if @params[:created_at_from].to_date > Date.today || @params[:created_at_to].to_date > Date.today
      "Created at date can't be in the future"
    end
  end

  def error
    validate
    '{"error":"' + @error + '"}' if @error
  end

  private

  def date_format_invalid?(date) #return true if invalid
    !(date.match(/^\d{4}-\d{2}-\d{2}$/) || date.match(/^\d{8}$/))
  end

  def validate
    @validations.each do |v|
      check = self.send(v)
      if !check.nil?
        @error = check
        break
      end
    end
  end

end
