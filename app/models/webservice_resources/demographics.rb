module WebserviceResources
  class Demographics #changed
    
    DEMOGRAPHIC_CODE_CLASSES = {
                                  "country_code" => Country,
                                  "employment_status_code" => EmploymentStatus, 
                                  "ethnicity_code" => Ethnicity, 
                                  "gender_code" => Gender, 
                                  "language_code" => Language, 
                                  "marital_status_code" => MaritalStatus, 
                                  "phone_type_code" => PhoneType, 
                                  "race_code" => Race,
                                  "state_code" => State,
                                  "drivers_license_state_code" => State,
                                  "student_status_code" => StudentStatus
                                }
                                
    def self.set_class(code)
      DEMOGRAPHIC_CODE_CLASSES[code]
    end
    
    def self.get_code_key(class_code)
      DEMOGRAPHIC_CODE_CLASSES.key(class_code)
    end
    
    # def self.get_fhir_codes
    #   return @fhir if defined?(@fhir)
    #   @fhir = YAML.load(File.open(Dir.pwd + '/config/fhir.yml'))
    # end
    
  end
end