module DemographicCodes
  class Converter
    def self.code_to_cc_id(attribute, code)
      begin
        attribute.values.each do |key, value|
          return key.to_s if value['values'].map{ |e| e.to_s.downcase }.include?(code.to_s.downcase)
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
