require 'sinatra'
require 'sinatra/reloader' if development?
require 'mongoid'
require 'slim'
require 'bootstrap-sass'
require 'redcarpet'
require 'rack-livereload'

configure do
  Mongoid.load!("./mongoid.yml")
end

use Rack::LiveReload

class Page
  include Mongoid::Document

  field :title, type: String
  field :content, type: String
end


get '/pages' do
  @pages = Page.all
  @title = "Simple CMS: Page list"
  slim :index
end

get '/pages/new' do
  @page = Page.new
  slim :new
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
