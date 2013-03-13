require 'sinatra'
require 'data_mapper'
require 'haml'
require 'sinatra/reloader'

DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/example.db")

class Link
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :url, Text
  property :score, Integer
  property :points, Integer, :default => 0
  property :created_at, Time
  property :author, String
  
  attr_accessor :score
  
  def calculate_score
    time_elapsed = (Time.now - self.created_at) / 3600
    self.score = ((self.points-1) / (time_elapsed+2)**1.8).real
  end
  
  def url
    stored_url = super
    if stored_url =~ /^http/
      return stored_url
    else
      return "http://#{stored_url}"
    end
  end
  
  def self.all_sorted_desc
    self.all.each { |item| item.calculate_score }.sort { |a,b| a.score <=> b.score }.reverse
  end
end

DataMapper.finalize.auto_upgrade!

get '/' do
  @links = Link.all :order => :id.desc
  haml :index
end

get '/hot' do
  @links = Link.all_sorted_desc 
  haml :index
end

post '/' do
  l = Link.new
  l.title = params[:title]
  l.url = params[:url]
  l.author = params[:author]
  l.created_at = Time.now
  l.save
  redirect to('/'), 302
end

put '/:id/vote/:type' do
  l = Link.get params[:id]
  l.points += params[:type].to_i
  l.save
  redirect back
end