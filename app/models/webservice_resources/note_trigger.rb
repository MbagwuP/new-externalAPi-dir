module WebserviceResources
  class NoteTrigger
    extend Client::Webservices
      
    def self.values
      cache_key = "note_triggers"
      cache_retrieval(cache_key, :list_all)
    end
  
    def self.list_all
      urlnt = webservices_uri "note_triggers/list_all.json"
      triggers = fetch_list(urlnt)
      format_list_for_converter(triggers)
    end
    
    def self.format_list_for_converter(note_triggers)
      note_triggers_assembly = {}
      note_triggers.each do |nt|
        note_trigger_assembly = {}
        note_trigger_assembly['values'] = [nt['note_trigger']['code'], nt['note_trigger']['id']]
        note_trigger_assembly['default'] = nt['note_trigger']['code']
        note_trigger_assembly['display'] = nt['note_trigger']['code']
        note_triggers_assembly[nt['note_trigger']['id']] = note_trigger_assembly
      end
      note_triggers_assembly
    end
  end
end