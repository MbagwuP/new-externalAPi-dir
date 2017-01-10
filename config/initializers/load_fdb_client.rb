config = HashWithIndifferentAccess.new(YAML::load_file(File.join(APP_ROOT, 'config', 'fdb.yml'))[ENV['RACK_ENV']])

FDBClient.configure do |fdb_client|
  fdb_client.api_base   = "#{config[:base_url]}/#{config[:version]}" rescue nil
  fdb_client.enabled    = config[:enabled] || false rescue false
  fdb_client.shared_key = "SHAREDKEY #{config[:client_id]}:#{config[:password]}" rescue nil
end
