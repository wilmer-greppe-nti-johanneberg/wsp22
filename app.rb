require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

include Model

enable :sessions

# Display Landing Page
#
get('/') do
    slim(:start)
end

# Displays Error Page 
#
get('/error') do
    error = session[:error]
    slim(:error,locals:{error:error})
end

# Checks login status before displaying games
# 
# @see Model#get_login_status
before('/games') do
    check_login_status()
end

# Checks login and admin status
# before displaying form to add a game
# 
# @see Model#get_login_status
# @see Model#get_admin_status
before('/games/new') do
    check_login_status()
    check_admin_rights()
end

# Checks login status before displaying game info
#
# @param [Integer] :id, the id of the game
# @see Model#get_login_status
before('/games/:id') do
    check_login_status()
end

# Checks login and admin status
# before displaying game info edit form
# 
# @param [Integer] :id, the id of the game
# @see Model#get_login_status
# @see Model#get_admin_status
before('/games/:id/edit') do
    check_login_status()
    check_admin_rights()
end

# Displays lists of games
#
# @see Model#get_games
get('/games') do
    result = get_games()
    slim(:"games/index",locals:{games:result,is_admin:session[:is_admin]})
end

# Displays form to add a new game
#
get('/games/new') do
    slim(:"games/new")
end

# Creates a new game and redirects to "/games"
#
# @param [String] title, The title of the game
# @param [Float] price, The price of the game
# @param [Array] tags, An array containing the tags of the game
# @param [String] studioname, The title of the game studio
# 
# @see Model#create_new_game
post('/games/new') do
    title = params[:title]
    price = params[:price].to_f
    tags = [params[:tag1],
            params[:tag2],
            params[:tag3],
            params[:tag4],
            params[:tag5]]
    studioname = params[:studioname]
    create_new_game(title, price, tags, studioname)
end

# Deletes selected game and redirects to /games
#
# @param [Integer] :id, id of selected game
#
# @see Model#delete_game
post('/games/:id/delete') do
    id = params[:id].to_i
    delete_game(id)
    redirect('/games')
end

# Edits game information and redirects to /games
#
# @param [Integer] :id, The id of the selected game
# @param [String] title, The title of the game
# @param [Float] price, The price of the game
# @param [Array] tags, An array containing the tags of the game
# @param [String] studioname, The title of the game studio
#
# @see Model#update_game_info
post('/games/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    price = params[:price].to_f
    tags = [
        params[:tag1],
        params[:tag2],
        params[:tag3],
        params[:tag4],
        params[:tag5]
    ]
    studio_name = params[:studio_name]
    update_game_info(id, title, price, tags, studio_name)
    redirect('/games')
end

# Displays form to update game info
#
# @param [Integer] :id, The id of the selected game
#
# @see Model#get_game_info
get('/games/:id/edit') do
    id = params[:id].to_i
    info = get_game_info(id)
    slim(:"/games/edit",locals:{result:info[0],studio:info[1],tags:info[2]})
end

# Displays info about the selected game
#
# @param [Integer] :id, The id of the selected game
#
# @see Model#get_game_info
get('/games/:id') do
    id = params[:id].to_i
    info = get_game_info(id)
    slim(:"games/show",locals:{game:info[0],studio:info[1],tags:info[2]})
end

# Creates a new user and redirects to start page if creating was successful
# If user creation failed, redirects to /error
#
# @param [String] username, The name of the created user
# @param [String] password, The password of the created user
# @param [String] password_confirm, Confirmation of selected password
# @param [Integer] usertype, Type of user which is created
# @param [String] admin_key, Key which needs to be entered when creating an admin account
#
# @see Model#register_user
post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    usertype = params[:usertype].to_i
    admin_key = params[:adminkey]
    register_user(username, password, password_confirm, usertype, admin_key)
end

# Displays login form
#
get('/login') do
    slim(:login)
end

# Logins user depending on username and password
# If login is successful then redirects to /games
#
# @param [String] username, username of account to login to
# @param [String] password, password of account to login to
#
# @see Model#login_user
post('/users/login') do
    username = params[:username]
    password = params[:password]
    login_user(username, password)
end