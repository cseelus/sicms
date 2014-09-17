require 'sinatra'
require 'sinatra/reloader' if development?
require 'mongoid'
require 'slim'
require 'sass'
require 'redcarpet'
require 'rack-livereload'


# Configuration
# ---------------------------------------------------------------------

# Slim
Slim::Engine.set_default_options pretty: true
# Rack
use Rack::LiveReload
# Assets
get('/views/assets/stylesheets/application.css'){ sass :'assets/stylesheets/application' }
# Mongoid
configure do
  Mongoid.load!("./mongoid.yml")
  enable :sessions
end


# helpers
# ---------------------------------------------------------------------

helpers do
  def admin?
    session[:admin]
  end

  def protected!
    halt 401, "You are not authorized to see this page." unless admin?
  end

  def url_for page
    if admin?
      "/pages/" + page.id
    else
      "/pages/" + page.permalink
    end
  end
end


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

get('/login'){ session[:admin]=true; redirect back }
get('/logout'){ session[:admin]=nil; redirect back }

get '/pages' do
  @pages = Page.all
  @title = "Simple CMS: Page list"
  slim :index
end

get '/pages/new' do
  protected!
  @page = Page.new
  slim :new
end

get '/pages/:permalink' do
  begin
    @page = Page.find_by(permalink: params[:permalink])
  rescue
    pass
  end
  slim :show
end

get '/pages/:id' do
  @page = Page.find(params[:id])
  @title = @page.title
  slim :show
end

get '/pages/:id/edit' do
  protected!
  @page = Page.find(params[:id])
  slim :edit
end

post '/pages' do
  protected!
  page = Page.create(params[:page])
  redirect to("pages/#{page.id}")
end

put '/pages/:id' do
  protected!
  page = Page.find(params[:id])
  page.update_attributes(params[:page])
  redirect to("/pages/#{page.id}")
end

get '/pages/delete/:id' do
  protected!
  @page = Page.find(params[:id])
  slim :delete
end

delete '/pages/:id' do
  protected!
  Page.find(params[:id]).destroy
  redirect to('/pages')
end
