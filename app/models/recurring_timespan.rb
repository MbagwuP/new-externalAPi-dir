class RecurringTimespan

  def initialize options
    @days_of_week = []
    @days_of_week << 0 if options[:use_sunday]
    @days_of_week << 1 if options[:use_monday]
    @days_of_week << 2 if options[:use_tuesday]
    @days_of_week << 3 if options[:use_wednesday]
    @days_of_week << 4 if options[:use_thursday]
    @days_of_week << 5 if options[:use_friday]
    @days_of_week << 6 if options[:use_saturday]

    @effective_from = Date.parse options[:effective_from] rescue nil
    @effective_to = Date.parse options[:effective_to] rescue nil
    @start_at = Time.parse options[:start_at] rescue nil
    @end_at = Time.parse options[:end_at] rescue nil
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
      x if @effective_from.nil?
      x if x >= @effective_from
    }.compact.map{|x|
      x if @effective_to.nil?
      x if x <= @effective_to
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
    Chronic.parse(date.to_s + ' ' + timestamp_segment(@start_at))
  end

  def add_end_time_to_date date
    Chronic.parse(date.to_s + ' ' + timestamp_segment(@end_at))
  end

  def timestamp_segment timestamp_string
    timestamp_string.to_s.split(' ')[1..-1].join
  end

end
