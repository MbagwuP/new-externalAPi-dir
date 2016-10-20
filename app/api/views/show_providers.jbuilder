json.array! @providers do |provider|
	json.partial! :provider, provider: provider 
end
