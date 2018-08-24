module WebserviceResources
  class Converter
    
    def self.code_to_cc_id(attribute, code)
      attribute.values.each do |key, value|
        if value['values'].map{ |e| e.to_s.downcase }.include?(code.to_s.downcase)
          return key.to_s
        end 
      end
      # If empty string passed as value then nullifys previous value
      return nil if code.blank?
      key_code = WebserviceResources::Demographics.get_code_key(attribute) || attribute.to_s.split("::")[1].underscore
      raise Error::InvalidRequestError.new("Invalid #{key_code}")
    end
    
    def self.name_to_cc_id(attribute, name)
      begin
        attribute.values.each do |key, value|
          return key.to_s if value['values'].map{ |e| e.to_s.downcase }.include?(name.to_s.downcase)
        end
        return ""
      rescue
        return ""
      end
    end

    def self.cc_id_to_code(attribute, id)
      begin
        return "" unless id.present?
        return id unless attribute.values[id].present?
        return attribute.values[id]['default']
      rescue
        return ""
      end
    end

    def self.id_to_name(attribute,id)
      #make the formatted list as the "name"
      attribute.values.each do |key, value|
        return value["name"] if (key.to_i).eql?(id.to_i)
      end
      return ""
    end
    
    def self.display_by_code(attribute, code)
      begin
        attribute.values.each do |key, value|
          return value['display'] if value['values'].map{ |e| e.to_s.downcase }.include?(code.to_s.downcase)
        end
        return ""
      rescue
        return ""
      end
    end
    
  end
end
