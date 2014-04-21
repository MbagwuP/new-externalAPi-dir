require File.expand_path('../../spec_helper.rb', __FILE__)

describe Sinatra::Example do
  
  describe "GET '/example'" do
    it "should be successful" do
      get '/example'
      last_response.should be_ok
    end
  end

end