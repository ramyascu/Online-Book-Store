#!/usr/local/bin/ruby -w
#myapp.rb

require 'pp'
require 'sinatra'
require 'sass'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:///#{Dir.pwd}/students.db")

# The student class is data mapped to a table in the database.
# This table contains the list of all students in the database.
class Student
  include DataMapper::Resource
  property :unique_id, Serial        # This is the primary key, not shown to the user
  property :student_id, Integer        # This is the student_id, shown to the user
  property :firstname, String
  property :lastname, String
  property :birthday, Date
  property :address, Text
  property :phone, String
  property :grade, String
end

# The comment class is mapped to a database table. 
class Comment
  include DataMapper::Resource
  property :unique_id, Serial        # This is the primary key, hidden from the user
  property :comment_title, String
  property :created_by, String
  property :comment, String
  property :created_at, DateTime    # This field is auto-populated by data-mapper
end

# We have created all the data models, so we can finalize and auto_upgrade
DataMapper.finalize
DataMapper.auto_migrate!

# Configurations
configure do
  use Rack::Session::Cookie, :secret => 'your_secret'
  set :username, "Admin"
  set :password, "COEN278"

  # Sinatra runs fine locally if I don't add below lines, but on heroku, the following
  # lines are required. Otherwise, it will search for the wrong directories
  set :views, File.dirname(__FILE__) + "/Views"
  set :public_folder, File.dirname(__FILE__) + "/Public"

end

# Route handler to display login page
get '/login' do
  @failed_login = false
  erb :login
end

# Route handler to process the data submitted via login page
post '/login' do
  if params[:username] == settings.username &&
    params[:password] == settings.password
    session[:admin] = true    # Set session cookie saying admin is logged ini
    redirect to ('/students')    # We can redirect to any page, but students page is the only one affected by login
  else
    @failed_login = true    # Setting this variable will make the login page display an appropriate message
    session[:admin] = false
    erb :login
  end
end

# Route handler for the logout navigation link
get '/logout' do
  if session[:admin] == true
    session.clear        # Clear the admin login page
    @logged_out = true    # Setting this value will display an appropriate message in the login page
  end
  erb :login            # We will show the login page on clicking logout link
end

# We are using scss for generating the style sheet
get '/styles.css' do
  scss :styles
end

# Route handler for the "/" page. Redirect to home page
get '/' do
  redirect to ('/home')
end



# Route handler for the home page
get '/home' do
  erb :home
end

# Route handler for the about page
get '/about' do
  erb :about
end

# Route handler for the contact page
get '/contact' do
  erb :contact
end

# Route handler for the students page
get '/students' do
  erb :students
end

# This route is for editing student records
get '/student_add_edit/:unique_id' do
  # Only admin can enter this part
  halt(401, 'Not Authorized') unless session[:admin]

  # Get the primary key from the route. @id is visible from the student_add_edit erb page
  @id = params[:unique_id]

  # Set a variable so student_add_edit knows that it is editing an existing record
  # and not adding a new record
  @new_record = false

  erb :student_add_edit
end

# Route handler for deleting a student record
get '/student_delete/:unique_id' do

  # Only admin can delete student records
  halt(401, 'Not Authorized') unless session[:admin]
  
  # From the route, get the primary key of the record to be deleted
  @id = params[:unique_id]

  # Delete the record corresponding to the primary key
  Student.get(@id).destroy

  # Go to the students page
  redirect to ('/students')
end

# This route is for adding or editing student records. We get here
# by an HTML post from the student record editing HTML page
post '/student_add_edit' do

  # Only admin must be able to add or edit student records
  halt(401, 'Not Authorized') unless session[:admin]

  # Initialize a hash @incorrect to empty value. We will add entries
  # to this hash if we find any of the form fields to be incorrect
  @incorrect = Hash.new

  # student_id is incorrect if it is empty or not positive.
  if params[:student_id].length == 0 || params[:student_id].to_i <= 0
    @incorrect[:student_id] = true # Mark student_id field as incorrect
  end

  # firstname should be one or more alphabets. Otherwise, it is marked incorrect.
  if not(/^[A-Za-z]+$/.match(params[:firstname]))
    @incorrect[:firstname] = true
  end

  # lastname should be one or more alphabets
  if not (/^[A-Za-z]+$/.match(params[:lastname]))
    @incorrect[:lastname] = true
  end

  # Birthday is incorrect if it is empty
  if params[:birthday].length == 0
    @incorrect[:birthday] = true
  end

  # Address is incorrect if it is empty
  if params[:address].length == 0
    @incorrect[:address] = true
  end

  # Phone number is incorrect if it has anything other than 0-9, plus, minus, brackets, #
  if not (/^[0-9+\-#()]+$/.match(params[:phone]))
    @incorrect[:phone] = true
  end

  # Grade should be upper case, A-F only
  if not (/^[A-F]$/.match(params[:grade]))
    @incorrect[:grade] = true
  end


  if @incorrect.length > 0
    # If any of the fields is incorrect, we must go back to the forms page.
    
    # Pass the original form contents through @old_values, so that we can fill up the 
    # form once we land there.
    @old_values = params.clone

    if params[:new_record] == "true"
      @new_record = true
    else
      @id = params[:unique_id]
      @new_record = false
    end

    erb :student_add_edit
  else

    # We got here because all of the fields are correct. So, we either create a new
    # record or modify an existing record.

    # The form which submitted data to this handler had a hidden field called 
    # new_record. This tells us whether the form was adding a new record or 
    # modifying an existing record.
 
    if params[:new_record] == "true"

      # We are creating a new record
      Student.create(:student_id => params[:student_id],
       :firstname => params[:firstname],
       :lastname => params[:lastname],
       :birthday => params[:birthday],
       :address => params[:address],
       :phone => params[:phone],
       :grade => params[:grade])
    else
      # We are modifying an existing record, so first get the class instance 
      # corresponding to the record. The form contains a hidden field called
      # unique_id which gives us the primary key of the record.
      x = Student.get(params[:unique_id])
      
      # Change the properties of the record
      x[:student_id] = params[:student_id]
      x[:firstname] = params[:firstname]
      x[:lastname] = params[:lastname]
      x[:birthday] = params[:birthday]
      x[:address] = params[:address]
      x[:phone] = params[:phone]
      x[:grade] = params[:grade]

      # Save the record
      x.save
    end

    # Whether we added a new record or modified an existing one, we go to the 
    # students page
    redirect to ('/students')
  end
end

# We get a post if we click on the "add new record" button on the students page. 
# This will take the browser to a form containing empty fields to add a new record.
post '/students' do

  # Only root is allowed to get here
  halt(401, 'Not Authorized') unless session[:admin]
  
  # Set @new_record to tell the student_add_edit page that we are adding a new record
  @new_record = true

  erb :student_add_edit
end

# Route handler for the comments page
get '/comment' do
  erb :comment
end

# We get here by clicking on the "add new comment" button at the end of the 
# comments page. This will take the browser to a form where comment can be 
# added.
post '/comment' do
  erb :comment_add
end

# We get here once we enter comment fields. We must validate the entries
# (make sure the fields are not zero). 
post '/comment_add' do

  # Create a new hash to keep note of invalid fields in the form
  @incorrect = Hash.new

  # Mark the "created_by field as invalid if it is empty
  if params[:created_by].length == 0
    @incorrect[:created_by] = true
  end

  # Mark the comments field as invalid if it is empty
  if params[:comment].length == 0
    @incorrect[:comment] = true
  end

  # Mark the title field as inivalid if it is empty
  if params[:comment_title].length == 0
    @incorrect[:comment_title] = true
  end

  if @incorrect.length > 0
    # If any of the fields are invalid, go back to the form.
    # Pass the invalid values back to the form (so user won't have to type
    # everything once again)
    @old_values = params.clone

    erb :comment_add
  else

    # All the comment fields were correct, so create a new comment 
    # and add it to the database
    Comment.create(:created_by => params[:created_by],
       :comment => params[:comment],
       :comment_title => params[:comment_title])

    redirect to ('/comment')
  end
end

# If we click on a link in the comments summary page, we should go to a page
# where the individual comment should be displayed. The :unique_id is passed 
# as a parameter to the comment_view page so it knows which record to display
get '/comment_view/:unique_id' do
  @id = params[:unique_id]
  erb :comment_view
end

# Route handler for the video page
get '/video' do
  erb :video
end











