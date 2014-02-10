module CareCloud
    class AuditRecord
        include MongoMapper::Document
        set_database_name "audit_events"
        
        key :uuid, String
        key :type, String
        key :severity, String
        key :ip_address, String
        key :statuscode, String
        key :duration, String
        key :request_method, String
        key :msg, String
        key :request_path, String
        key :request_body, String
        key :response_body, String
        timestamps!
        
        before_validation :ensure_uuid
        
        def ensure_uuid
            self.uuid = SecureRandom.hex(16) if self.uuid.nil?
        end
    end
end

