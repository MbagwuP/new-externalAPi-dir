module CircuLab
  class LabRequest < CircuLab::LabRequestParser
    # This class handles the building of the response. 
    attr_accessor :approved_labs, :unapproved_labs

    def initialize(request_body)
      super(request_body)
      @lab_request_template             = lab_request_template
      @lab_order_template_files         = lab_order_template_files
      @lab_order_templates              = lab_order_templates
      @approved_labs, @unapproved_labs  = labs_partition
    end


    def lab_request_template
      # This is the common outer wrapper for a lab result response. The first part of building our response.
      # We read a json file and return a parsed map of key=>values with their default values. 
      JSON.parse(File.open("app/modules/circulab/lab_test_results/lab_request.json").read).symbolize_keys
    end

    def lab_order_template_files
      # A collection of file names that pertain to the orders in this directory
      Dir.glob("app/modules/circulab/lab_test_results/orders/*.json")
    end

    def lab_order_templates
      # A collection of maps that contain the lab order template files. 
      @lab_order_template_files.map {|lab| 
        {File.basename(lab) => JSON.parse(File.open(lab).read)}.symbolize_keys
      }
    end 

    def labs_partition
      # We want to make sure that the lab test in the request match the labs we 
      # have avilable as templates. If all the labs in the request match what 
      # we have available in our orders directory, then we can continue building
      # the response.
      # 
      # We call this method in the initializer and use partition to create a
      # collection of two arrays. If the last array contains an entry, then we know that
      # at least one of the labs in the request is an unapproved lab and we skip the
      # build process. 
      # 
      # We will only allow requests where we can build a result for each lab to 
      # go through

      lab_test_file_names.partition { |file| 
        @lab_order_template_files.member?(orders_file_path(file))
      }
    end

    def meets_circulab_response_criteria?
      # Boolean check to see if we have an entry in our unapproved labs array.
      # If this is empty we can continue building the response. 
      @unapproved_labs.empty?
    end

    def generate_approved_lab_orders
      # We iterate through our list of approved labs and then filter the lab
      # value from our parsed_lab_test collection. This collection contains 
      # our parsed lab values which we will used to merge and overwrite the values
      # in our Lab Order template. 
      # 
      # This returns a collection a Lab Orders
 
      @lab_orders = @approved_labs.map { |lab_name|
        lab_basename    = File.basename(lab_name).to_sym
        parsed_lab_test = parsed_lab_tests.select {
                            |lab| (lab).member?(lab_basename)
                          }.map { |lab| 
                            lab.values
                          }.flatten.first
        LabOrder.new(orders_file_path(lab_name), parsed_lab_test).generate
      }
    end

    def build_lab_request_response
      # Utility function to build and complete our full lab request response.
      # 
      # This returns a map with all of the parsed and generated values for our Lab Order results
      template               = @lab_request_template.merge!(parsed_lab_tracer)
      template[:lab_request] = template[:lab_request].symbolize_keys.merge!(parsed_lab_request)
      template[:lab_request][:orders] = generate_approved_lab_orders
      template
    end
  end
end