class RecurringTimespan

  def initialize options
    options.symbolize_keys!
    @days_of_week = []
    @days_of_week << 0 if options[:use_sunday]
    @days_of_week << 1 if options[:use_monday]
    @days_of_week << 2 if options[:use_tuesday]
    @days_of_week << 3 if options[:use_wednesday]
    @days_of_week << 4 if options[:use_thursday]
    @days_of_week << 5 if options[:use_friday]
    @days_of_week << 6 if options[:use_saturday]

    @timezone_offset = options[:timezone_offset]
    @timezone_name = options[:timezone_name]

    if has_hour_and_minute_fields? options
      @start_at = hour_and_minute_to_time(options[:start_hour], options[:start_minutes])
      @end_at = hour_and_minute_to_time(options[:end_hour], options[:end_minutes])
      @start_hour = options[:start_hour]
      @end_hour = options[:end_hour]
    else
      @start_at = Time.parse options[:start_at] rescue nil
      @end_at = Time.parse options[:end_at] rescue nil
    end

    @effective_from = Date.parse options[:effective_from] rescue nil
    @effective_to = Date.parse options[:effective_to] rescue nil
  end

  def occurences_in_date_range filter_start_date, filter_end_date, as_strings=nil
    filter_start_date = Date.parse(filter_start_date) if filter_start_date.is_a?(String)
    filter_end_date = Date.parse(filter_end_date) if filter_end_date.is_a?(String)
    result = (filter_start_date..filter_end_date).to_a.select {|k| @days_of_week.include?(k.wday)}
    filtered = filter_by_effective_dates result
    filtered.map{|x|
      start_and_end_for_occurence x
    }
  end

  private

  def filter_by_effective_dates array_of_dates
    array_of_dates.map{|x|
      (x if @effective_from.nil?) || (x if x >= @effective_from)
    }.compact.map{|x|
      (x if @effective_to.nil?) || (x if x <= @effective_to) || nil
    }.compact
  end

  def start_and_end_for_occurence date
    output = {
      start_at: add_start_time_to_date(date),
      end_at: add_end_time_to_date(date)
    }
    if @start_hour && @end_hour
      output[:start_at] = iso8601_change_hour(output[:start_at].iso8601, @start_hour)
      output[:end_at] = iso8601_change_hour(output[:end_at].iso8601, @end_hour)
    else
      output[:start_at] = iso8601_change_hour(output[:start_at].iso8601, @start_at.hour)
      output[:end_at] = iso8601_change_hour(output[:end_at].iso8601, @end_at.hour)
      # output[:start_at] = output[:start_at].iso8601
      # output[:end_at] = output[:end_at].iso8601
    end
    output
  end

  def add_start_time_to_date date
    Time.use_zone(@timezone_name) do 
      Chronic.parse(date.to_s + ' ' + timestamp_segment(@start_at)).in_time_zone
    end
  end

  def add_end_time_to_date date
    Time.use_zone(@timezone_name) do
      Chronic.parse(date.to_s + ' ' + timestamp_segment(@end_at)).in_time_zone
    end
  end

  # gets just the time part off of a timestamp that also has the date in it
  def timestamp_segment timestamp_string
    timestamp_string.to_s.split(' ')[1..-1].join
  end

  def has_hour_and_minute_fields? options
    (options.keys & [:start_hour, :end_hour, :start_minutes, :end_minutes]).any?
  end

  def number_with_preceding_zero number
    number.to_s.rjust(2,"0")
  end

  def hour_and_minute_to_time hour, minute
    hour   = number_with_preceding_zero(hour)
    minute = number_with_preceding_zero(minute)
    time = Time.use_zone(@timezone_name){ Time.zone.parse("#{hour}:#{minute}") }
  end

  def iso8601_change_hour iso8601_str, new_hour
    iso8601_str[11..12] = number_with_preceding_zero(new_hour)
    iso8601_str
  end

  def iso8601_get_hour iso8601_str
    iso8601_str[11..12]
  end

end
