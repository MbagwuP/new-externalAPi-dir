module CircuLab
  class LabOrder
    # This class will handle the merging of the parsed data for a Lab Order
    # and also generates a collection of Lab Results
    def initialize(lab_name, parsed_lab_test)
      @lab_name        = lab_name
      @parsed_lab_test = parsed_lab_test
      @order           = order
    end

    def order
      # This will open an order template and merge the values from the 
      # parsed_lab_test map
      order = JSON.parse(File.open(@lab_name).read).symbolize_keys rescue nil
      order.merge!(@parsed_lab_test)
    end

    def create_results
      # Iteratates through the default results map and generates a Lab Result per 
      # result.
      # 
      # returns a collection of LabResults
      @order[:results].map { |result|
        LabResult.new(result).generate
      }
    end

    def generate
      # Generates the LabResults for each order and assigns the collection 
      # to the results key.
      @order[:results] = create_results
      @order
    end
  end
end