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
      start_and_end_for_occurence x, as_strings
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

  def start_and_end_for_occurence date, as_strings=nil
    output = {
      start_at: add_start_time_to_date(date),
      end_at: add_end_time_to_date(date)
    }
    output.each {|k,v| output[k] = v.iso8601} if as_strings
    output
  end

  def add_start_time_to_date date
    Time.use_zone(@timezone_name) do 
      dt = Chronic.parse(date.to_s + ' ' + timestamp_segment(@start_at)).in_time_zone
      dt = dt - 1.hour if dt.dst?
      dt
    end
  end

  def add_end_time_to_date date
    Time.use_zone(@timezone_name) do
      dt = Chronic.parse(date.to_s + ' ' + timestamp_segment(@end_at)).in_time_zone
      dt = dt - 1.hour if dt.dst?
      dt
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
    time += 1.hour if time.dst?
  end

end
