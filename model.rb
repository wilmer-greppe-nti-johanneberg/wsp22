# Funktioner för app.rb
module Model
    
    # Gets a database object
    #
    # @param [String] path, path to the database file
    #
    # @return [Database] database object
    def get_database(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end
    
    # Checks if user is logged in
    # If not logged in, redirects to error page
    #
    # @param [Integer] :id, id of user who is logged in
    def check_login_status()
        if session[:id] == nil
            session[:error] = "Du måste vara inloggad för att se detta innehåll!"
            redirect('/error')
        end
    end
    
    # Checks if user has admin rights
    # If admin rights doesn't exist, redirects to error page
    #
    # @param [Integer] :id, id of user who is logged in
    #
    # @see Model#get_database
    def check_admin_rights()
        db = get_database('db/data.db')
        user = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
        if user["usertype"] != 2
            session[:error] = "Du har ej behörighet att visa innehållet"
            redirect('/error')
        end
    end
    
    # Checks if entered game tags are unique
    # 
    # @params [Array] tags, Array containing game tags
    #
    # @return [Boolean] true if all elements are unique
    def check_for_unique_tags(tags)
        temp = tags.uniq
        return tags == temp
    end
    
    # Gets all games from database
    #
    # @see Model#get_database
    #
    # @return [Hash]
    #   * :id [Integer] id of game
    #   * :title [String] title of game
    #   * :price [Float] price of game
    #   * :studio_id [Integer] id of gamestudio
    def get_games()
        db = get_database('db/data.db')
        return db.execute("SELECT * FROM games")
    end
    
    # Creates a new game and redirects to "/games"
    #
    # @param [String] title, The title of the game
    # @param [Float] price, The price of the game
    # @param [Array] tags, An array containing the tags of the game
    # @param [String] studioname, The title of the game studio
    #
    # @see Model#get_database
    def create_new_game(title, price, tags, studioname)
        if !check_for_unique_tags(tags)
            session[:error] = "Taggarna är inte unika"
            redirect('/error')
        end
        db = get_database('db/data.db')
        studio = db.execute("SELECT id FROM studios WHERE name = ?",studioname).first
        if studio == nil
            db.execute("INSERT INTO studios (name) VALUES (?)",studioname)
            studio = db.execute("SELECT id FROM studios WHERE name = ?",studioname).first
        end
        result = db.execute("SELECT * FROM games WHERE title = ?",title)
        genres = []
        tags.each do |tag|
            genres.append(db.execute("SELECT id FROM genres WHERE title = ?",tag).first)
        end
        if result.empty?
            db.execute("INSERT INTO games (title,price,studio_id) VALUES (?,?,?)",title,price,studio["id"])
            game = db.execute("SELECT id FROM games WHERE title = ?",title).first
            genres.each do |genre|
                db.execute("INSERT INTO game_genre_relation (game_id,genre_id) VALUES (?,?)",game["id"],genre["id"])
            end
            redirect('/games')
        else
            session[:error] = "Ett fel uppstod: Spelet finns redan!"
            redirect('/error')
        end
    end
    
    # Deletes selected game
    #
    # @param [Integer] id, id of selected game
    # @see Model#get_database
    def delete_game(id)
        db = get_database('db/data.db')
        db.execute("DELETE FROM games WHERE id = ?",id)
        db.execute("DELETE FROM game_genre_relation WHERE game_id = ?",id)
    end
    
    # Edits game information and redirects to /games
    #
    # @param [Integer] id, The id of the selected game
    # @param [String] title, The title of the game
    # @param [Float] price, The price of the game
    # @param [Array] tags, An array containing the tags of the game
    # @param [String] studioname, The title of the game studio
    # @see Model#get_database
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
    
    # Gets info about a game
    #
    # @param [Integer] id, Id of the game
    #
    # @see Model#get_database
    #
    # @return [Array]
    #   * result [Hash] game information
    #       * :id [Integer] id of game
    #       * :title [String] title of game
    #       * :price [Float] price of game
    #       * :studio_id [Integer] id of gamestudio
    #   * studio [Hash] studio information
    #       * :id [Integer] studio id
    #       * :name [String] name of studio
    #   * tags [Array]
    #       * [Hash]
    #           * :title [String] Tag name
    #       * [Hash]
    #           * :title [String] Tag name
    #       * [Hash]
    #           * :title [String] Tag name
    #       * [Hash]
    #           * :title [String] Tag name
    #       * [Hash]
    #           * :title [String] Tag name
    def get_game_info(id)
        db = get_database('db/data.db')
        result = db.execute("SELECT * FROM games WHERE id = ?",id).first
        p result
        studio = db.execute("SELECT * FROM studios WHERE id = ?",result["studio_id"]).first
        tags = db.execute("SELECT title FROM genres INNER JOIN game_genre_relation ON genres.id == game_genre_relation.genre_id WHERE game_genre_relation.game_id = ?",id)
        return [result, studio, tags]
    end
    
    # Adds user to database and redirects to start page
    # If adding new user failed, redirects to /error
    #
    # @param [String] username, The name of the created user
    # @param [String] password, The password of the created user
    # @param [String] password_confirm, Confirmation of selected password
    # @param [Integer] usertype, Type of user which is created
    # @param [String] admin_key, Key which needs to be entered when creating an admin account
    #
    # @see Model#get_database
    def register_user(username, password, password_confirm, usertype, admin_key)
        current_admin_key = "NTI2022"
        if usertype == 2 && admin_key != current_admin_key
            session[:error] = "Du saknar behörighet att skapa adminkonto!"
            redirect('/error')
        end
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
    
    # Logins user depending on username and password
    # If login is successful then redirects to /games
    # Otherwise redirects to /error
    #
    # @param [String] username, username of account to login to
    # @param [String] password, password of account to login to
    #
    # @see Model#get_database
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
end