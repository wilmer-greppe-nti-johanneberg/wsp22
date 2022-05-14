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
# @see Model#check_login_status
before('/games') do
    if !check_login_status(session[:id])
        session[:error] = "Du måste vara inloggad för att se detta innehåll!"
        redirect('/error')
    end
end

# Checks login and admin status
# before displaying form to add a game
# 
# @see Model#check_login_status
# @see Model#check_admin_rights
before('/games/new') do
    if !check_login_status(session[:id]) || !check_admin_rights(session[:id])
        session[:error] = "Du har ej behörighet att visa innehållet"
        redirect('/error')
    end
end

# Checks login status before displaying game info
#
# @param [Integer] :id, the id of the game
# @see Model#check_login_status
before('/games/:id') do
    if !check_login_status(session[:id])
        session[:error] = "Du måste vara inloggad för att visa innehållet"
        redirect('/error')
    end
end

# Checks login and admin status
# before displaying game info edit form
# 
# @see Model#check_login_status
# @see Model#check_admin_rights
before('/games/:id/edit') do
    if !check_login_status(session[:id]) || !check_admin_rights(session[:id])
        session[:error] = "Du har ej behörighet att visa innehållet"
        redirect('/error')
    end
end

# Checks login status before displaying user comments
#
# @param [Integer] :id, the id of current user
# @see Model#check_login_status
before('/comments') do
    if !check_login_status(session[:id])
        session[:error] = "Du måste vara inloggad för att visa innehållet"
        redirect('/error')
    end
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
post('/games') do
    title = params[:title]
    price = params[:price].to_f
    tags = [params[:tag1],
            params[:tag2],
            params[:tag3],
            params[:tag4],
            params[:tag5]]
    studioname = params[:studioname]
    if title == "" or params[:tag1] = "" or params[:tag2] = "" or params[:tag3] = "" or params[:tag4] = "" or params[:tag5] = "" or studio_name == ""
        session[:error] = "Fälten får inte vara tomma"
        redirect('/error')
    end
    if create_new_game(title, price, tags, studioname)
        redirect('/games')
    else
        session[:error] = "Spelet kunde inte skapas, kolla så att taggarna är unika eller om spelet redan finns."
        redirect('/error')
    end
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
    if title == "" or params[:tag1] = "" or params[:tag2] = "" or params[:tag3] = "" or params[:tag4] = "" or params[:tag5] = "" or studio_name == 
        session[:error] = "Fälten får inte vara tomma"
        redirect('/error')
    end
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
# @see Model#get_related_comments
get('/games/:id') do
    id = params[:id].to_i
    user_id = session[:id]
    info = get_game_info(id)
    comments = get_related_comments(id)
    slim(:"games/show",locals:{game:info[0],studio:info[1],tags:info[2],comments:comments})
end

# Creates a new user and redirects to game page if creating was successful
# If user creation failed, redirects to /error
#
# @param [String] username, The name of the created user
# @param [String] password, The password of the created user
# @param [String] password_confirm, Confirmation of selected password
# @param [Integer] usertype, Type of user which is created
# @param [String] admin_key, Key which needs to be entered when creating an admin account
#
# @see Model#register_user
post('/users') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    usertype = params[:usertype].to_i
    admin_key = params[:adminkey]
    if username == "" or password == "" or password_confirm == ""
        session[:error] = "Fälten får inte vara tomma"
        redirect('/error')
    end
    if !register_user(username, password, password_confirm, usertype, admin_key)
        session[:error] = "Skapandet av användaren misslyckades."
        redirect('/error')
    else
        redirect('/games')
    end
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
    if username == "" or password == ""
        session[:error] = "Fälten får inte vara tomma"
        redirect('/error')
    end
    if session[:last_login] != nil
        if Time.now - session[:last_login] < 5
            session[:error] = "Du måste vänta längre mellan inloggningar"
            redirect('/error')
        end
    end
    if !login_user(username, password)
        session[:error] = "Inloggningen misslyckades, fel lösenord eller användarnamn."
        redirect('/error')
    else
        session[:last_login] = Time.now
        redirect('/games')
    end
end

# Displays comment form for a game
#
get('/comments/:id/new') do
    session[:current_game] = params[:id]
    slim(:"/comments/new")
end

# Adds new comment to database
#
# @param [String] comment, comment that user wrote
# @param [Integer] game_id, id of current game
# @param [Integer] user_id, id of current user
#
# @see Model#add_comment
post('/comments') do
    comment = params[:comment]
    game_id = session[:current_game]
    user_id = session[:id]
    add_comment(comment,game_id,user_id)
    redirect('/games')
end

# Displays all user comments
#
# @param [Integer] id, id of current user
#
# @see Model#get_user_comments
get('/comments') do
    id = session[:id]
    comments = get_user_comments(id)
    slim(:"/comments/index",locals:{comments:comments})
end

# Deletes comment
#
# @param [Integer] id, id of comment
#
# @see Model#delete_comment
post('/comments/:id/delete') do
    id = params[:id]
    if !check_edit_rights(id,session[:id])
        session[:error] = "Du har inte behörighet"
        redirect('/error')
    end
    delete_comment(id)
    redirect('/games')
end

# Checks if user has rights to edit commet before showing edit form
before('/comments/:id/edit') do
    if !check_edit_rights(params[:id],session[:id])
        session[:error] = "Du har inte behörighet"
        redirect('/error')
    end
end

# Shows form to edit comment
#
# @param [Integer] id, id of comment
#
# @see Model#get_comment_info
# @see Model#get_database
get('/comments/:id/edit') do
    id = params[:id]
    comment = get_comment_info(id)
    slim(:"comments/edit",locals:{comment:comment})
end

# Edits comment
#
# @param [Integer] id, id of comment
# @param [String] comment, comment from user
#
# @see Model#edit_comment
post('/comments/:id/edit') do
    id = params[:id]
    comment = params[:comment]
    if comment == ""
        session[:error] = "Fältet får inte vara tomt"
        redirect('/error')
    end
    edit_comment(id,comment)
    redirect('/games')
end