require 'sinatra'
require 'json'

before do
  if request.request_method == "POST" and request.content_type=="application/json"
    body_parameters = request.body.read
    parsed = body_parameters && body_parameters.length >= 2 ? JSON.parse(body_parameters) : nil
    params.merge!(parsed)
  end
end

before '/protected/*' do
  puts 'protected'
end

get '/' do
  'Hello World'
end

get '/protected/:name' do
  "Hello #{params[:name]}"
end

get '/example.json' do
  content_type :json
  { :key1 => 'value1', :key2 => 'value2' }.to_json
end

post '/jsonpost' do
  var1 = JSON.parse(request.body.read)
  puts var1
  puts params
end
