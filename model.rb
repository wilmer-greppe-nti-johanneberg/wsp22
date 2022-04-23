# Funktioner för app.rb

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

def delete_game(id)
    db = get_database('db/data.db')
    db.execute("DELETE FROM games WHERE id = ?",id)
    db.execute("DELETE FROM game_genre_relation WHERE game_id = ?",id)
end

def update_game_info(id, title, price, tags, studio_name)
    db = get_database('db/data.db')
    result = db.execute("SELECT id FROM studios WHERE name = ?",studio_name).first
    if result == nil
        db.execute("INSERT INTO studios (name) VALUES (?)",studio_name)
        result = db.execute("SELECT id FROM studios WHERE name = ?",studio_name).first
    end
    game = db.execute("SELECT id FROM games WHERE title = ?",title).first
    db.execute("UPDATE games SET title=?,price=?,studio_id=? WHERE id = ?",title,price,result["id"],id)
    currenttags = db.execute("SELECT genre_id FROM game_genre_relation WHERE game_id = ?",id)
    tags_id = []
    tags.each do |currenttag|
        tags_id.append(db.execute("SELECT id FROM genres WHERE title = ?",currenttag).first)
    end
    relations = []
    currenttags.each do |currenttag|
        relations.append(db.execute("SELECT id FROM game_genre_relation WHERE game_id = ? AND genre_id = ?",game["id"],currenttag["genre_id"]).first)
    end
    i = 0
    while i < 5
        db.execute("UPDATE game_genre_relation SET genre_id=? WHERE id = ?",tags_id[i]["id"],relations[i]["id"])
        i += 1
    end
end

def get_game_info(id)
    db = get_database('db/data.db')
    result = db.execute("SELECT * FROM games WHERE id = ?",id).first
    studio = db.execute("SELECT * FROM studios WHERE id = ?",result["studio_id"]).first
    tags = db.execute("SELECT title FROM genres INNER JOIN game_genre_relation ON genres.id == game_genre_relation.genre_id WHERE game_genre_relation.game_id = ?",id)
    return [result, studio, tags]
end

def register_user(username, password, password_confirm, usertype)
    db = get_database('db/data.db')
    result = db.execute("SELECT id FROM users WHERE username = ?", username)
    if result.empty?
        if password == password_confirm
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users (username,password,usertype) VALUES(?,?,?)", username,password_digest,usertype)
            redirect('/')
        else
            session[:error] = "Ett fel uppstod: Lösenorden matchade inte!"
            redirect('/error')
        end
    else
        session[:error] = "Ett fel uppstod: Användaren finns redan!"
        redirect('/error')
    end
end

def login_user(username, password)
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
        end
    end
    session[:error] = "Fel lösenord eller användarnamn!"
    redirect('/error')
end