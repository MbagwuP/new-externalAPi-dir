class RecallStatus
  attr_reader :id,:code, :name


  def initialize(id,code,name=nil)
    @id = id
    @code = code
    @name = name
  end

  def self.parse_to_webservices(name)
    webservices_map[name]
  end

  private
  def self.webservices_map
    @webservices_map ||= fetch.each_with_object({}) do |recall_status,h|
      h[parse_name_to_code(recall_status.name)] = recall_status.id
    end
  end

  def self.fetch
    url = ApiService::API_SVC_URL + "recalls/list_all_recall_statuses.json"
    request = RestClient::Request.new(url: url, method: :get, headers: {api_key: APP_API_KEY})
    resp = CCAuth::InternalService::Request.sign!(request).execute
    Oj.load(resp).map {|js| 
      RecallStatus.new(js['recall_status']['id'],js['recall_status']['code'],js['recall_status']['name']) 
    }
  end

  def self.parse_name_to_code(name)
    name.strip.underscore.gsub(' ', '_')
  end

  def webservices_map
    self.class.webservices_map
  end
  
end
