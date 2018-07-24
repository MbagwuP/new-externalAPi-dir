module WebserviceResources
  class Language
    extend Client::Webservices
      
    def self.values
      cache_key = "language-codes"
      cache_retrieval(cache_key, :language_codes_from_webservices)
    end

    def self.language_codes_from_webservices
      languages = rescue_service_call('Language Look Up',true) do
        RestClient.get(webservices_uri "people/list_all_languages.json", :api_key => ApiService::APP_API_KEY)
      end
      languages = JSON.parse languages
      languages_assembly = {}
      languages.each do |language|
        language['language']['iso6392'] = '' unless language['language']['iso6392'].present?
        lang_assembly = {}
        lang_assembly['values'] = [language['language']['iso6392'], language['language']['id']]
        lang_assembly['default'] = language['language']['iso6392']
        lang_assembly['display'] = language['language']['name']
        languages_assembly[language['language']['id']] = lang_assembly
      end
      languages_assembly
    end
  end
end
