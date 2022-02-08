require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

def get_database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

get('/') do
    slim(:start)
end

get('/games') do
    db = get_database('db/data.db')
    test = db.execute("SELECT * FROM games")
    p test
    slim(:"games/index")
end