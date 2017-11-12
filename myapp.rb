#!/usr/local/bin/ruby -w
#myapp.rb

require 'pp'
require 'sinatra'
require 'sass'
require 'dm-core'
require 'dm-migrations'

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/students.db")

class Students
  include DataMapper::Resource
  property :student_id, Serial
  property :firstname, String
  property :lastname, String
  property :birthday, Date
  property :address, Text
  property :phone, String
  property :grade, String
end
# DataMapper.finalize
DataMapper.auto_migrate!


configure do
  use Rack::Session::Cookie, :secret => 'your_secret'
  set :username, "yuan"
  set :password, "newnew"
end

get '/login' do
  @failed_login = false
  erb :login
end

post '/login' do
  if params[:username] == settings.username &&
    params[:password] == settings.password

    session[:admin] = true
    redirect to ('/students')
  else
    @failed_login = true
    session[:admin] = false
    erb :login
  end
end

get '/logout' do
  if session[:admin] == true
    session.clear
    @logged_out = true
  end
  erb :login
end

get '/styles.css' do
  scss :styles
end

get '/home' do
  erb :home
end

get '/about' do
  erb :about
end

get '/contact' do
  erb :contact
end

get '/students' do
  erb :students
end

get '/comment' do
  erb :comment
end

get '/video' do
  erb :video
end









