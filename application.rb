require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require File.join(File.dirname(__FILE__), 'environment')

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
  DataMapper.finalize
end

# Add the configure development block here
configure :development do
  DataMapper.auto_upgrade!
  before do
    puts '[Params]'
      p params
  end
end

configure do

  SiteConfig = OpenStruct.new(
          :title => 'Sinatra Shortener',
          :author => 'Your Name Can Go Here',
          :url_base => 'http://localhost:4567/' # the url of your application
        )
        
  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
  
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/shorturls.db")

end


error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error - ' + env['sinatra.error'].message
end

helpers do  
    include Rack::Utils  
    alias_method :h, :escape_html
       
    # Add helper methods here
    def generate_short_url(long_url)
	  @shortcode = random_string 5
	  
	  su = ShortURL.first_or_create(
	            { :url => long_url  }, 
	            {
	              :short_url  =>  @shortcode,
	              :created_at =>  Time.now,
	              :updated_at =>  Time.now
	            })
	    
	  @shortenedURL = get_site_url(su.short_url)
	end

    def random_string(length)
		rand(36**length).to_s(36)
	end

	def get_site_url(short_url)
		SiteConfig.url_base + short_url
	end
end


# Add your routes here
get '/' do
	if params[:url] and not params[:url].empty?
		generate_short_url(params[:url])
	else
    	@urls = ShortURL.all;
    	erb :index	
  	end
end

post '/' do

  if params[:url] and not params[:url].empty?
    generate_short_url(params[:url])
  end
  @urls = ShortURL.all;
  erb :index
end



["/get/:short_url", "/:short_url"].each do |path|
	get path do
	  @URLData = ShortURL.get(params[:short_url])
	  if @URLData
	    # log the click in the database		
	    ct = ClickTrack.new
	    ct.attributes	=	{ 
	      :short_url 	=> 	params[:short_url],
	      :url		=>	@URLData.url,	
	      :clicked_at	=>	Time.now
	    }
	    ct.save	
	    redirect @URLData.url
	  else
	    'No short url found'
	  end
	end
end

get '/expand/:hash/?' do
  @URLData = ShortURL.get(params[:hash])	
  if @URLData
    content_type :json
      { :url => get_site_url(@URLData.short_url), 
        :long_url => @URLData.url, 
        :hash => params[:hash] 
      }.to_json
  else
    content_type :json
    { :message => 'No hash parameter was specified or no short URL was found to match the provided hash' }.to_json
  end
end

