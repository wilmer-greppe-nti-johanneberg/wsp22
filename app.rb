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

get('/') do
    slim(:start)
end

get('/games') do
    if session[:id] == nil
        "Du måste vara inloggad för att se spelen!"
    else
        db = get_database('db/data.db')
        result = db.execute("SELECT * FROM games")
        user = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
        is_admin = user["usertype"] == 2
        slim(:"games/index",locals:{games:result,is_admin:is_admin})
    end
end

get('/games/new') do
    if session[:id] == nil
        "Du måste vara inloggad för att se spelen!"
    else
        db = get_database('db/data.db')
        user = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
        if user["usertype"] == 2
            slim(:"games/new")
        else
            "Du har ej behörighet att visa denna sida!"
        end
    end
end

post('/games/new') do
    title = params[:title]
    price = params[:price].to_f
    studioname = params[:studioname]
    db = get_database('db/data.db')
    studio = db.execute("SELECT id FROM studios WHERE name = ?",studioname).first
    if studio == nil
        db.execute("INSERT INTO studios (name) VALUES (?)",studioname)
        studio = db.execute("SELECT id FROM studios WHERE name = ?",studioname).first
    end
    result = db.execute("SELECT * FROM games WHERE title = ?",title)
    if result.empty?
        db.execute("INSERT INTO games (title,price,studio_id) VALUES (?,?,?)",title,price,studio["id"])
        redirect('/games')
    else
        "Ett fel uppstod: Spelet finns redan!"
    end
end

post('/games/:id/delete') do
    id = params[:id].to_i
    db = get_database('db/data.db')
    db.execute("DELETE FROM games WHERE id = ?",id)
    redirect('/games')
end

post('/games/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    price = params[:price].to_f
    studio_name = params[:studio_name]
    db = get_database('db/data.db')
    result = db.execute("SELECT id FROM studios WHERE name = ?",studio_name).first
    if result == nil
        db.execute("INSERT INTO studios (name) VALUES (?)",studio_name)
        result = db.execute("SELECT id FROM studios WHERE name = ?",studio_name).first
    end
    db.execute("UPDATE games SET title=?,price=?,studio_id=? WHERE id = ?",title,price,result["id"],id)
    redirect('/games')
end

get('/games/:id/edit') do
    id = params[:id].to_i
    db = get_database('db/data.db')
    result = db.execute("SELECT * FROM games WHERE id = ?",id).first
    result2 = db.execute("SELECT * FROM studios WHERE id = ?",result["studio_id"]).first
    slim(:"/games/edit",locals:{result:result,result2:result2})
end

get('/games/:id') do
    if session[:id] == nil
        "Du måste vara inloggad för att se spelen!"
    else
        id = params[:id].to_i
        db = get_database('db/data.db')
        result = db.execute("SELECT * FROM games WHERE id = ?",id).first
        studio = db.execute("SELECT name FROM studios WHERE id IN (SELECT studio_id FROM games WHERE id = ?)",id).first
        slim(:"games/show",locals:{game:result,studio:studio})
    end
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
            redirect('/games')
        else
            "Fel lösenord eller användarnamn!"
        end
    else
        "Fel lösenord eller användarnamn!"
    end
end