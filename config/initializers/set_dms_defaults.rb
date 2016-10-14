config = File.join(APP_ROOT, 'config', 'dms.yml')
CCloudDmsClient::DocumentApi.endpoint = YAML.load(ERB.new(File.read(config)).result)[ApiService.settings.environment.to_s][:url]
