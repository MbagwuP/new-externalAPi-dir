require_relative 'myapp'
require 'test/unit'
require 'rack/test'

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_basic_request
    get '/'
    assert_equal 'Hello World', last_response.body
  end

  def test_get_name
    get '/protected/bryan'
    assert_equal 'Hello bryan', last_response.body
  end

  def test_post_trans
    val1 = { :key1 => 'val1', :key2 => 'val2' }.to_json
    post '/jsonpost', val1, "CONTENT_TYPE" => 'application/json'
  end

end
