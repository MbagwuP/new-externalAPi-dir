json.providers @providers do |provider|
	json.partial! :base_provider, provider: provider 
end