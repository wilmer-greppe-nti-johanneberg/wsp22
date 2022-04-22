require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def get_database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def check_login_status()
    if session[:id] == nil
        session[:error] = "Du måste vara inloggad för att se detta innehåll!"
        redirect('/error')
    end
end

def check_admin_rights()
    db = get_database('db/data.db')
    user = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
    if user["usertype"] != 2
        session[:error] = "Du har ej behörighet att visa innehållet"
        redirect('/error')
    end
end

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
    db = get_database('db/data.db')
    db.execute("DELETE FROM games WHERE id = ?",id)
    db.execute("DELETE FROM game_genre_relation WHERE game_id = ?",id)
    redirect('/games')
end

post('/games/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    price = params[:price].to_f
    tag1 = params[:tag1]
    tag2 = params[:tag2]
    tag3 = params[:tag3]
    tag4 = params[:tag4]
    tag5 = params[:tag5]
    studio_name = params[:studio_name]
    db = get_database('db/data.db')
    result = db.execute("SELECT id FROM studios WHERE name = ?",studio_name).first
    if result == nil
        db.execute("INSERT INTO studios (name) VALUES (?)",studio_name)
        result = db.execute("SELECT id FROM studios WHERE name = ?",studio_name).first
    end
    game = db.execute("SELECT id FROM games WHERE title = ?",title).first
    db.execute("UPDATE games SET title=?,price=?,studio_id=? WHERE id = ?",title,price,result["id"],id)

    currenttags = db.execute("SELECT genre_id FROM game_genre_relation WHERE game_id = ?",id)
    genre1 = db.execute("SELECT id FROM genres WHERE title = ?",tag1).first
    genre2 = db.execute("SELECT id FROM genres WHERE title = ?",tag2).first
    genre3 = db.execute("SELECT id FROM genres WHERE title = ?",tag3).first
    genre4 = db.execute("SELECT id FROM genres WHERE title = ?",tag4).first
    genre5 = db.execute("SELECT id FROM genres WHERE title = ?",tag5).first
    relation1 = db.execute("SELECT id FROM game_genre_relation WHERE game_id = ? AND genre_id = ?",game["id"],currenttags[0]["genre_id"]).first
    relation2 = db.execute("SELECT id FROM game_genre_relation WHERE game_id = ? AND genre_id = ?",game["id"],currenttags[1]["genre_id"]).first
    relation3 = db.execute("SELECT id FROM game_genre_relation WHERE game_id = ? AND genre_id = ?",game["id"],currenttags[2]["genre_id"]).first
    relation4 = db.execute("SELECT id FROM game_genre_relation WHERE game_id = ? AND genre_id = ?",game["id"],currenttags[3]["genre_id"]).first
    relation5 = db.execute("SELECT id FROM game_genre_relation WHERE game_id = ? AND genre_id = ?",game["id"],currenttags[4]["genre_id"]).first
    db.execute("UPDATE game_genre_relation SET genre_id=? WHERE id = ?",genre1["id"],relation1["id"])
    db.execute("UPDATE game_genre_relation SET genre_id=? WHERE id = ?",genre2["id"],relation2["id"])
    db.execute("UPDATE game_genre_relation SET genre_id=? WHERE id = ?",genre3["id"],relation3["id"])
    db.execute("UPDATE game_genre_relation SET genre_id=? WHERE id = ?",genre4["id"],relation4["id"])
    db.execute("UPDATE game_genre_relation SET genre_id=? WHERE id = ?",genre5["id"],relation5["id"])
    redirect('/games')
end

get('/games/:id/edit') do
    id = params[:id].to_i
    db = get_database('db/data.db')
    result = db.execute("SELECT * FROM games WHERE id = ?",id).first
    result2 = db.execute("SELECT * FROM studios WHERE id = ?",result["studio_id"]).first
    tags = db.execute("SELECT title FROM genres INNER JOIN game_genre_relation ON genres.id == game_genre_relation.genre_id WHERE game_genre_relation.game_id = ?",id)
    slim(:"/games/edit",locals:{result:result,result2:result2,tags:tags})
end

get('/games/:id') do
    id = params[:id].to_i
    db = get_database('db/data.db')
    result = db.execute("SELECT * FROM games WHERE id = ?",id).first
    studio = db.execute("SELECT name FROM studios WHERE id IN (SELECT studio_id FROM games WHERE id = ?)",id).first
    tags = db.execute("SELECT title FROM genres INNER JOIN game_genre_relation ON genres.id == game_genre_relation.genre_id WHERE game_genre_relation.game_id = ?",id)
    slim(:"games/show",locals:{game:result,studio:studio,tags:tags})
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    usertype = params[:usertype]
    db = get_database('db/data.db')

    result = db.execute("SELECT id FROM users WHERE username = ?", username)

    if result.empty?
        if password == password_confirm
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users (username,password,usertype) VALUES(?,?,?)", username,password_digest,usertype)
            redirect('/')
        else
            "Ett fel uppstod: Lösenorden matchade inte!"
        end
    else
        "Ett fel uppstod: Användaren finns redan!"
    end
end

get('/login') do
    slim(:login)
end

post('/users/login') do
    username = params[:username]
    password = params[:password]
    db = get_database('db/data.db')
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result != nil
        pwdigest = result["password"]
        id = result["id"]
        if BCrypt::Password.new(pwdigest) == password
            session[:id] = id
            user = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
            if user["usertype"] == 2
                session[:is_admin] = true
            end
            redirect('/games')
        else
            "Fel lösenord eller användarnamn!"
        end
    else
        "Fel lösenord eller användarnamn!"
    end
end