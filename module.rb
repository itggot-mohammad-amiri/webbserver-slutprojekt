module ChatDB

    DBPATH = "./db/table.squlite"

    def db_connect()
        db = SQLite3::Database.new("db/table.sqlite") 
        return db 
    end 

    def db_message()
        db = db_connect()
        messages = db.execute("SELECT * FROM msg")
        return messages
    end

    def db_nwmsg(username, message)
        db = db_connect()
        db.execute("INSERT INTO msg(username, message) VALUES (?, ?)", [username, message])
    end 
    
    def db_reg(username)
        db = db_connect()
        test = db.execute("SELECT user_id FROM user WHERE username=?", [username])
        return test
    end
    
    def db_reg2(username, email, password)
        db = db_connect()
        db.execute("INSERT INTO user(username, email, crypt_password) VALUES (?,?,?)", [username, email, password])
    end
    
    def db_login(login_username)
        db = db_connect()
        db.results_as_hash = true
        db.execute("SELECT user_id,crypt_password FROM user WHERE username=?", [login_username])
    end

    def db_addfriend(user1, user2) 
        db = db_connect()
        db.execute("INSERT INTO user_relations(user1,user2) VALUES (?,?)", [user1, user2])    
    end

    def db_getid(username)
        db = db_connect()
        db.execute("SELECT user_id FROM user WHERE username=?", [username])
    end

    def relation(user)
        db = db_connect()
        relation = db.execute("SELECT user2 FROM user_relations WHERE user1=?", [user]).join(" ").split(" ")
        return relation 
    end
    
    # def user_relation(user1, user2)
    #     db = db_connect()
    #     result = db.execute("SELECT relation FROM user_relations WHERE (user1 = ? OR user2 = ?) AND (user1 = ? OR user2 = ?)", [user1, user1, user2, user2])
    #     if result.empty==false
    #         if result[0][0]==1
    #             return "this user is your friend"
    #         end
    #     else
    #         return "This user is not your friend!"
    #     end
    # end

    def db_profile(username)
        db = db_connect
        profile = db.execute("SELECT * FROM user WHERE username =?", [username]) 
        return profile   
    end

    def db_users()
        db = db_connect
        users = db.execute("SELECT * FROM user") 
        return users   
    end
    
end