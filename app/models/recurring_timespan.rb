class RecurringTimespan

  def initialize options
    options = options.symbolize_keys
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

    # we need an integer for the hour portions of the start and end times
    # this integer won't be affected by time zone parses
    if has_hour_and_minute_fields? options
      # it's a blockout
      @start_at = hour_and_minute_to_time(options[:start_hour], options[:start_minutes])
      @end_at = hour_and_minute_to_time(options[:end_hour], options[:end_minutes])
      @start_hour_eastern = options[:start_hour]
      @end_hour_eastern = options[:end_hour]
    else
      # it's a template, so extract the original hour from the timestamp
      practice_timezone do
        @start_at = Time.parse options[:start_at] rescue nil
        @end_at = Time.parse options[:end_at] rescue nil
      end
      @start_hour_eastern = iso8601_get_hour(options[:start_at]).to_i
      @end_hour_eastern = iso8601_get_hour(options[:end_at]).to_i
    end

    # in Postgres, the start and end times for both templates and blockouts are saved in Eastern Time, ignoring DST
    # now that we have an integer for the hours, adjust them from Eastern Time to the Practice's local time
    @start_hour = @start_hour_eastern + eastern_to_practice_hour_difference
    @end_hour = @end_hour_eastern + eastern_to_practice_hour_difference

    @effective_from = Date.parse options[:effective_from] rescue nil
    @effective_to = Date.parse options[:effective_to] rescue nil
  end

  def occurences_in_date_range filter_start_date, filter_end_date
    filter_start_date = Date.parse(filter_start_date) if filter_start_date.is_a?(String)
    filter_end_date = Date.parse(filter_end_date) if filter_end_date.is_a?(String)
    result = (filter_start_date..filter_end_date).to_a.select {|k| @days_of_week.include?(k.wday)}
    filtered = filter_by_effective_dates result
    filtered.map{|x|
      start_and_end_for_occurence x
    }
  end

  # grab just the time portion of the full timestamp, using today's date for DST considerations
  def practice_start_time
    start_time_string = add_start_time_to_date(Date.today.iso8601)
    iso8601_change_hour(start_time_string.iso8601, @start_hour)[11..24]
  end

  def practice_end_time
    end_time_string = add_end_time_to_date(Date.today.iso8601)
    iso8601_change_hour(end_time_string.iso8601, @end_hour)[11..24]
  end

  def effective_from_iso8601_date
    @effective_from.iso8601 rescue nil
  end

  def effective_to_iso8601_date
    @effective_to.iso8601 rescue nil
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
    # @start_at and @end_at are reliable for the offset with regards to DST, but not for the actual hour..
    # so, replace the hours in the occurences with the original hours from the input hash
    output[:start_at] = iso8601_change_hour(output[:start_at].iso8601, @start_hour)
    output[:end_at] = iso8601_change_hour(output[:end_at].iso8601, @end_hour)
    output
  end

  def add_start_time_to_date date
    practice_timezone do 
      DateTime.strptime(date.to_s + ' ' + timestamp_segment(@start_at), '%Y-%m-%d %H:%M:%S%z').in_time_zone
    end
  end

  def add_end_time_to_date date
    practice_timezone do
      DateTime.strptime(date.to_s + ' ' + timestamp_segment(@end_at), '%Y-%m-%d %H:%M:%S%z').in_time_zone
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
    time = practice_timezone { DateTime.strptime("#{hour}:#{minute}","%H:%M").in_time_zone }
  end

  # these take an iso8601 string, for example:
  # "2014-09-24T14:00:00-04:00"
  def iso8601_change_hour iso8601_str, new_hour
    iso8601_str[11..12] = number_with_preceding_zero(new_hour)
    iso8601_str
  end

  def iso8601_get_hour iso8601_str
    iso8601_str[11..12]
  end

  def self.iso8601_get_offset_as_integer iso8601_str
    iso8601_str[-6..-4].to_i
  end

  # used only for testing
  def timezone_offset_as_integer
    @timezone_offset[0..2].to_i
  end

  def eastern_timezone
    Time.use_zone('Eastern Time (US & Canada)') { Time.zone }
  end

  def practice_timezone
    if block_given?
      Time.use_zone(@timezone_name){ yield }
    else
      Time.use_zone(@timezone_name) { Time.zone }
    end
  end

  # find the integer difference in hours between Eastern Time and the Practice's local time
  def eastern_to_practice_hour_difference
    (practice_timezone.utc_offset - eastern_timezone.utc_offset) / 60 / 60
  end

end
