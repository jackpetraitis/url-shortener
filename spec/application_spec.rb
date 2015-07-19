require_relative '../application.rb'
require 'rack/test'

set :environment, :test

def app
	Sinatra::application
end

describe 'URL Shortening Service' do |


|
	include Rack::Test::Methods

	it "should load the home page" do
		get '/'
		last_response.should be_ok
	end

	it "should pass when a short url is viewed directly" do
		get '/jirey'
		last_response.should be_ok
	end

	it "should fail when trying to expand a hash that hasn't been sent" do
		get '/expand'
		last_response.should_not be_ok
	end
	
end