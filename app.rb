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
        slim(:"games/index",locals:{games:result})
    end
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    usertype = params[:usertype]
    db = get_database('db/data.db')

    result = db.execute("SELECT id FROM users WHERE username=?", username)

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
    pwdigest = result["password"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        redirect('/games')
    else
        "Fel lösenord eller användarnamn!"
    end
end