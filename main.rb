require 'sinatra'
require 'sinatra/reloader' if development?
require 'mongoid'
require 'slim'
require 'bootstrap-sass'
require 'redcarpet'
require 'rack-livereload'


# Configuration
# ---------------------------------------------------------------------

# Mongoid
configure do
  Mongoid.load!("./mongoid.yml")
end
# Slim
Slim::Engine.set_default_options pretty: true
# Rack
use Rack::LiveReload
# Assets
get('/views/assets/stylesheets/application.css'){ sass :'assets/stylesheets/application' }


# Models
# ---------------------------------------------------------------------

class Page
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
  field :permalink, type: String, default: -> { make_permalink }

  def make_permalink
    title.parameterize if title
  end
  def parameterize(string, sep = '-')
    # Turn unwanted chars into the separator
    parameterized_string.gsub!(/[^a-z0-9\-_]+/, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
    end
    parameterized_string.downcase
  end
end


# Routes
# ---------------------------------------------------------------------

get '/pages' do
  @pages = Page.all
  @title = "Simple CMS: Page list"
  slim :index
end

get '/pages/new' do
  @page = Page.new
  slim :new
end

get '/:permalink' do
  begin
    @page = Page.find_by(permalink: params[:permalink])
  rescue
    pass
  end
  slim :show
end

get '/pages/:id/edit' do
  @page = Page.find(params[:id])
  slim :edit
end

get '/pages/:id' do
  @page = Page.find(params[:id])
  @title = @page.title
  slim :show
end

post '/pages' do
  page = Page.create(params[:page])
  redirect to("pages/#{page.id}")
end

put '/pages/:id' do
  page = Page.find(params[:id])
  page.update_attributes(params[:page])
  redirect to("/pages/#{page.id}")
end

get '/pages/delete/:id' do
  @page = Page.find(params[:id])
  slim :delete
end

delete '/pages/:id' do
  Page.find(params[:id]).destroy
  redirect to('/pages')
end
