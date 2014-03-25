web_path = Dir.pwd + "/config/webservice.yml"
web_config = YAML.load(File.open(web_path))[ApiService.settings.environment.to_s]
#CCloudWebServices::WebService.endpoint = web_config