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
    #
    # @return [Boolean] false if no account is logged in
    def check_login_status(id)
        if id == nil
            return false
        end
        return true
    end
    
    # Checks if user has admin rights
    # If admin rights doesn't exist, redirects to error page
    #
    # @param [Integer] id, id of user who is logged in
    #
    # @see Model#get_database
    #
    # @return [Boolean] returns false if no account is logged in
    def check_admin_rights(id)
        db = get_database('db/data.db')
        user = db.execute("SELECT usertype FROM users WHERE id = ?",id).first
        if user["usertype"] != 2
            return false
        end
        return true
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
    
    # Creates a new game
    #
    # @param [String] title, The title of the game
    # @param [Float] price, The price of the game
    # @param [Array] tags, An array containing the tags of the game
    # @param [String] studioname, The title of the game studio
    #
    # @see Model#check_for_unique_tags
    # @see Model#get_database
    #
    # @return [Boolean] true if game was successfully created
    def create_new_game(title, price, tags, studioname)
        if !check_for_unique_tags(tags)
            return false
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
            return true
        else
            return false
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
    #
    # @return [Boolean] true if new account was created
    def register_user(username, password, password_confirm, usertype, admin_key)
        current_admin_key = "NTI2022"
        if usertype == 2 && admin_key != current_admin_key
            return false
        end
        db = get_database('db/data.db')
        result = db.execute("SELECT id FROM users WHERE username = ?", username)
        if result.empty?
            if password == password_confirm
                password_digest = BCrypt::Password.create(password)
                db.execute("INSERT INTO users (username,password,usertype) VALUES(?,?,?)", username,password_digest,usertype)
                return true
            else
                return false
            end
        else
            return false
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
    #
    # @return [Array]
    #   * [Boolean] true if user was logged in
    #   * [Integer] id of user who was logged in
    #   * [Boolean] true if user who was logged in an admin account
    def login_user(username, password)
        db = get_database('db/data.db')
        result = db.execute("SELECT * FROM users WHERE username = ?",username).first
        if result != nil
            pwdigest = result["password"]
            id = result["id"]
            if BCrypt::Password.new(pwdigest) == password
                user = db.execute("SELECT usertype FROM users WHERE id = ?",id).first
                return [true, id, user["usertype"] == 2]
            end
        end
        return false
    end

    # Adds comment to database
    #
    # @param [String] comment, comment from user
    # @param [Integer] game_id, id of current game
    # @param [Integer] user_id, id of current user
    #
    # @see Model#get_database
    def add_comment(comment,game_id,user_id)
        db = get_database('db/data.db')
        db.execute("INSERT INTO game_user_relation (game_id,user_id,comment) VALUES (?,?,?)",game_id,user_id,comment)
    end

    # Gets all comments related to current game
    #
    # @param [Integer] game_id, id of current game
    #
    # @return [Array] array containing hashes with every related comment
    def get_related_comments(game_id)
        db = get_database('db/data.db')
        return db.execute("SELECT * FROM game_user_relation WHERE game_id = ?",game_id)
    end

    # Gets all comments related to current user
    #
    # @param [Integer] user_id, id of current user
    #
    # @return [Array] array containing hashes with every related comment
    def get_user_comments(user_id)
        db = get_database('db/data.db')
        return db.execute("SELECT * FROM game_user_relation WHERE user_id = ?",user_id)
    end

    # Checks if user has the right to edit comment or is admin
    #
    # @param
    #
    # @see Model#get_database
    #
    def check_edit_rights(id,logged_in_user)
        db = get_database('db/data.db')
        user = db.execute("SELECT user_id FROM game_user_relation WHERE id = ?",id).first
        if check_admin_rights(logged_in_user) or logged_in_user == user['user_id']
            return true
        end
        return false
    end

    # Deletes comment from database
    #
    # @param [Integer] id, id of comment
    #
    # @see Model#get_database
    def delete_comment(id)
        db = get_database('db/data.db')
        db.execute("DELETE FROM game_user_relation WHERE id = ?",id)
    end

    # Get comment description
    #
    # @param [Integer] id, id of comment
    #
    # @see Model#get_database
    #
    # @return [Hash] hash containing comment info
    def get_comment_info(id)
        db = get_database('db/data.db')
        return db.execute("SELECT * FROM game_user_relation WHERE id = ?",id).first
    end

    # Edits comment in database
    #
    # @param [Integer] id, id of comment 
    # @param [String] comment, comment from user
    #
    # @see Model#get_database
    def edit_comment(id,comment)
        db = get_database('db/data.db')
        db.execute("UPDATE game_user_relation SET comment = ? WHERE id = ?",comment,id)
    end
end