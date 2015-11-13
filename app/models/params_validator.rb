class ParamsValidator

  def initialize params, *args
    @params      = params
    @validations = args
  end

  def invalid_date_passed
    begin
      Date.parse(@params[:start_date]) if @params[:start_date]
      Date.parse(@params[:end_date])   if @params[:end_date]
      nil
    rescue
      'Dates must be valid dates in the format YYYY-MM-DD.'
    end
  end

  def blank_date_field_passed
    if (@params.keys.include?('start_date') && @params[:start_date].blank?) || (@params.keys.include?('end_date') && @params[:end_date].blank?)
      'Date filtering fields cannot be blank.'
    end
  end

  def missing_one_date_filter_field
    if [@params[:start_date], @params[:end_date]].compact.length == 1
      'Both start_date and end_date are required for date filtering.'
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

  def error
    validate
    '{"error":"' + @error + '"}' if @error
  end

  private

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
