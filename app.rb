class App < Sinatra::Base
	enable:sessions  

	get '/' do
		slim(:home)
	end

	get '/register' do
		slim(:register)
	end 

	post '/register' do
		db = SQLite3::Database.open("db/table.sqlite")
		username = params[:Username]
		password = params[:Password]
		hashed_password = BCrypt::Password.create(password)
		db.execute("INSERT INTO User(email,username, password) VALUES(?,?)", [username, hashed_password])
		id = db.execute("SELECT id FROM login WHERE username =?", [username])
		session[:user_id] = id
		redirect("/")
	end
	
	get '/login' do
		slim(:login)
	end

	post '/login' do
		login_username = params[:login_username]
		login_password = params[:login_password]
		
		db = SQLite3::Database.open("db/table.sqlite")
		hashed_password= db.execute("SELECT password FROM login WHERE username =?", login_username )[0][0]
		hashed_password = BCrypt::Password.new(hashed_password)

		if hashed_password == login_password 
			redirect("/user")
			session[:login]=true
		else
			redirect("/")
		end
	end 
	
	get '/user' do
		slim :user 
	end
	
	post '/logout' do
		session[:login] = false
		redirect("/") 
	end

end           
