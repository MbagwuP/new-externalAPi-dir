require "health_check/version"
require "health_check/middleware"

module HealthCheck

  class Result
    attr_accessor :records, :description

    def initialize(description)
      @records = []
      @description = description
    end

    def execute(test)
      test.clear; record(test.probe)
    rescue Exception => e
      @records << ["Probe Exception", false, "#{e.class}: #{e.message}"]
    end

    def body
      description.merge({service_status: service_status})
    end

    def record(probe)
      @records << probe.records
    end

    def service_status
      statuses = records.flatten(1).select { |r| r[1] == false }.map { |r| r[3] }
      status = if statuses.include?('critical') 
                 "down"
               elsif statuses.include?('warn')  
                 "sick"
               else 
                 "up"
               end
      status
    end

    def success?
      service_status != "down"
    end
  end

  class << self
    attr_accessor :key, :probes, :config, :app_setting

    def start_health_monitor
      load_from_config if config
    end

    def load_from_config
      dir = File.expand_path(File.join('..', '..', 'probes'), __FILE__)
      files = (config['probes'] || []).collect { |f| f.split(':') } # ['probe','level']

      require "#{dir}/probe.rb"
      
      files.each do |file|
        f = Dir["#{dir}/#{file[0]}.rb"][0]
        if f
          require f
          probe = "Probes::#{File.basename(f, '.rb').camelize}".constantize.new
          probe.level = file[1] || "warn"
          register(probe)
        end
      end
    end
    
    def register(klass)
      list = probes[klass.level.to_s] ||= []
      list << klass
      self
    end

    def execute(description={})
      result = HealthCheck::Result.new(description)
      probes.values.flatten(1).each { |p| result.execute(p) }
      result
    end

  end
  @probes = {}
  @key = nil

end
