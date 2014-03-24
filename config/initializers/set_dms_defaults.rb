dms_path = Dir.pwd + "/config/dms.yml"
dms_config = YAML.load(File.open(dms_path))[ApiService.settings.environment.to_s]
CCloudDmsClient::DocumentApi.endpoint = dms_config