module CircuLab
  class LabResult
    # This class will generate a new random observation value for each results
    # that falls within a believable high/low range
    attr_accessor :low_range, :high_range

    def initialize(result)
      @result = result
      @observation_value = @result["observation_value"]
      @reference_range   = @result["reference_range"]
      @timestamp         = DateTime.now.strftime("%Y%m%d%H%M")
      @at_times          = @timestamp + "T093000-0400"
    end

    def is_float?(value)
      # Utility method to check if the value is a float. 
      # Seems a bit hacky but using the Float type won't work the way we want
      # 
      value.to_s.split(".").size > 1
    end

    def is_obseravtion_value_float?
      # Boolean check if observation value is a float.
      is_float?(@observation_value)
    end

    def reference_range_exists?
      # Boolean check if result has a reference range
      @reference_range.to_s.strip.length > 0
    end

    def split_reference_range
      # Split the low/high reference range. 
      @reference_range.split("-")
    end

    def create_new_reference_range
      # Split the reference range and call the transform methods to return
      # two new ranges
      # 
      # Why are we transforming the reference range??? 
      # 
      # Good Question. If we want to simulate an observation result, it's not fun to only
      # simulate a result that falls within the acceptable range for a healthy person.
      # We should also see results that are above and blow the acceptable range in order
      # to create a more realistic result. 
      # 

      low_range, high_range = split_reference_range
      @low_range, @high_range  = transform_low_range(low_range), transform_high_range(high_range)
    end

    def generate_observation_value_from_range
      # We generate a new observation value from the updated ranges 
      create_new_reference_range
      transform_float(rand(@low_range..@high_range))
    end

    def transform_float(value)
      # The observation value can be either a float or whole number. 
      # And if it is a float it can have one or two decimal places. 
      # 
      # The value that's passed in comes in as a raw float which is a number 
      # with many decimal places. The original observation value contains the proper
      # number formatting we want to return so we use that to count the number 
      # of decimal places and return a correct value accordingly.

      decimal_count = @observation_value.to_s.split(".").last.size
      if decimal_count
        sprintf("%.#{decimal_count}f", value).to_f
      else 
        value.round
      end
    end

    def transform_low_range(range)
      # Case / When that returns a low range value depending on the original
      # value
        value = range.to_f
        low_range = case value
                    when 0.2..0.5
                      value - rand(0.0..0.2)
                    when 0.6..1
                      value - rand(0.0..0.2)
                    when 2..5
                      value - rand(1.0..2.0)
                    when 6..20
                      value - rand(1.0..5.0)
                    when value > 21 
                      value - rand(5.0..10.0)
                    else
                      value
                    end
        transform_float(low_range.abs)
    end

    def transform_high_range(range)
      # Case / When that returns a high range value depending on the original
      # value
        value = range.to_f
        high_range = case value
                      when 0.2..0.5
                        value + rand(0.0..0.1)
                      when 0.6..1
                        value + rand(0.0..0.5)
                      when 2..5
                        value + rand(1.0..5.0)
                      when 6..20
                        value + rand(1.0..5.0)
                      when value > 21 
                        value + rand(5.0..10.0)
                      else
                        value
                      end
        transform_float(high_range.abs)
    end

    def generate_observation_value
      # If there is no reference range then we just manipiulate the observation
      # value listed by returning a number slightly higher or lower 
      value = @observation_value.to_i
      case value
      when 0..4
        rand(value..5)
      when 5..10 
        rand(value - 2..value + 2)
      when 11..50
        rand(value - 5..value + 5)
      when value > 50
        rand(value - 10..value + 10)
      else
        value
      end
    end

    def create_observation_value
      # Creates a new random observation value
      if reference_range_exists?
        generate_observation_value_from_range
      else
        generate_observation_value
      end
    end

    def generate
      # Generates a lab result map with a new observation value
      @result["observation_value"] = create_observation_value.to_s
      @result["observation_at"]    = @at_times 
      @result["observation_date"]  = @timestamp
      @result.symbolize_keys
    end

  end
end