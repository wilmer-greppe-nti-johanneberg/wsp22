require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
    slim(:start)
end

get('/error') do
    error = session[:error]
    slim(:error,locals:{error:error})
end

before('/games') do
    check_login_status()
end

before('/games/new') do
    check_login_status()
    check_admin_rights()
end

before('/games/:id') do
    check_login_status()
end

before('/games/:id/edit') do
    check_login_status()
    check_admin_rights()
end

get('/games') do
    p session[:is_admin]
    db = get_database('db/data.db')
    result = db.execute("SELECT * FROM games")
    slim(:"games/index",locals:{games:result,is_admin:session[:is_admin]})
end

get('/games/new') do
    slim(:"games/new")
end

# Flytta till model.rb OCH förhindra att taggarna är samma
post('/games/new') do
    title = params[:title]
    price = params[:price].to_f
    tag1 = params[:tag1]
    tag2 = params[:tag2]
    tag3 = params[:tag3]
    tag4 = params[:tag4]
    tag5 = params[:tag5]
    studioname = params[:studioname]
    db = get_database('db/data.db')
    studio = db.execute("SELECT id FROM studios WHERE name = ?",studioname).first
    if studio == nil
        db.execute("INSERT INTO studios (name) VALUES (?)",studioname)
        studio = db.execute("SELECT id FROM studios WHERE name = ?",studioname).first
    end
    result = db.execute("SELECT * FROM games WHERE title = ?",title)
    genre1 = db.execute("SELECT id FROM genres WHERE title = ?",tag1).first
    genre2 = db.execute("SELECT id FROM genres WHERE title = ?",tag2).first
    genre3 = db.execute("SELECT id FROM genres WHERE title = ?",tag3).first
    genre4 = db.execute("SELECT id FROM genres WHERE title = ?",tag4).first
    genre5 = db.execute("SELECT id FROM genres WHERE title = ?",tag5).first
    if result.empty?
        db.execute("INSERT INTO games (title,price,studio_id) VALUES (?,?,?)",title,price,studio["id"])
        game = db.execute("SELECT id FROM games WHERE title = ?",title).first
        db.execute("INSERT INTO game_genre_relation (game_id,genre_id) VALUES (?,?)",game["id"],genre1["id"])
        db.execute("INSERT INTO game_genre_relation (game_id,genre_id) VALUES (?,?)",game["id"],genre2["id"])
        db.execute("INSERT INTO game_genre_relation (game_id,genre_id) VALUES (?,?)",game["id"],genre3["id"])
        db.execute("INSERT INTO game_genre_relation (game_id,genre_id) VALUES (?,?)",game["id"],genre4["id"])
        db.execute("INSERT INTO game_genre_relation (game_id,genre_id) VALUES (?,?)",game["id"],genre5["id"])
        redirect('/games')
    else
        "Ett fel uppstod: Spelet finns redan!"
    end
end

post('/games/:id/delete') do
    id = params[:id].to_i
    delete_game(id)
    redirect('/games')
end

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

get('/games/:id/edit') do
    id = params[:id].to_i
    info = get_game_info(id)
    slim(:"/games/edit",locals:{result:info[0],studio:info[1],tags:info[2]})
end

get('/games/:id') do
    id = params[:id].to_i
    info = get_game_info(id)
    slim(:"games/show",locals:{game:info[0],studio:info[1],tags:info[2]})
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    usertype = params[:usertype]
    register_user(username, password, password_confirm, usertype)
end

get('/login') do
    slim(:login)
end

post('/users/login') do
    username = params[:username]
    password = params[:password]
    login_user(username, password)
end