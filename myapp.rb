#!/usr/local/bin/ruby -w
#myapp.rb

require 'pp'
require 'sinatra'
require 'sass'
require 'data_mapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:///#{Dir.pwd}/students.db")

class Student
  include DataMapper::Resource
  property :unique_id, Serial
  property :student_id, Integer
  property :firstname, String
  property :lastname, String
  property :birthday, Date
  property :address, Text
  property :phone, String
  property :grade, String
end

class Comment
  include DataMapper::Resource
  property :unique_id, Serial
  property :comment_title, String
  property :created_by, String
  property :comment, String
  property :created_at, DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!


configure do
  use Rack::Session::Cookie, :secret => 'your_secret'
  set :username, "yuan"
  set :password, "newnew"
end

configure :development do
    #setup sqlite database
end

configure :production do
    #setup ENV[…]  database
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

get '/student_add_edit/:unique_id' do
  halt(401, 'Not Authorized') unless session[:admin]
  @id = params[:unique_id]
  @new_record = false
  erb :student_add_edit
end

get '/student_delete/:unique_id' do
  halt(401, 'Not Authorized') unless session[:admin]
  @id = params[:unique_id]
  Student.get(@id).destroy
  redirect to ('/students')
end

post '/student_add_edit' do
  halt(401, 'Not Authorized') unless session[:admin]
  if params[:new_record] == "true"
    Student.create(:student_id => params[:student_id],
                   :firstname => params[:firstname],
                   :lastname => params[:lastname],
                   :birthday => params[:birthday],
                   :address => params[:address],
                   :phone => params[:phone],
                   :grade => params[:grade])
  else
    x = Student.get(params[:unique_id])
    x[:student_id] = params[:student_id]
    x[:firstname] = params[:firstname]
    x[:lastname] = params[:lastname]
    x[:birthday] = params[:birthday]
    x[:address] = params[:address]
    x[:phone] = params[:phone]
    x[:grade] = params[:grade]
    x.save
  end
  redirect to ('/students')
end

post '/students' do
  halt(401, 'Not Authorized') unless session[:admin]
  @new_record = true
  erb :student_add_edit
end



get '/comment' do
  erb :comment
end

post '/comment' do
  erb :comment_add
end


post '/comment_add' do
  Comment.create(:created_by => params[:created_by],
                 :comment => params[:comment],
                 :comment_title => params[:comment_title])
  redirect to ('/comment')
end

get '/comment_view/:unique_id' do
  @id = params[:unique_id]
  erb :comment_view
end


get '/video' do
  erb :video
end











