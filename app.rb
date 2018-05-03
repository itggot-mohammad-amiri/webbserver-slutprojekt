class App < Sinatra::Base
	enable:sessions
	
	set :server, 'thin'
	set :sockets, []

    db = SQLite3::Database.new("db/table.sqlite") 

	def set_error(error_message)
		session[:error] = error_message
	end

	def get_error()
		error = session[:error]
		session[:error] = nil
		return error
	end

	get '/' do
		slim(:home, locals:{logged:session[:login]})
	end

	get('/error') do
		slim(:error)
	end

	get '/room' do
		if session[:user_id]
			if !request.websocket?
				messages = db.execute("SELECT * FROM msg")
				slim(:room, locals:{messages: messages}) 
			else
				request.websocket do |ws|
					ws.onopen do
						ws.send("")
						settings.sockets << ws
					end
					ws.onmessage do |msg| 
						EM.next_tick { settings.sockets.each{|s|
							 s.send(session[:username].to_s + ":" + msg)}}
						if msg.empty?
							set_error('Skriv något')
						else 
							db.execute("INSERT INTO msg(username, message) VALUES (?, ?)", [session[:username], msg])
						end 
					end
					ws.onclose do
						warn("ladda om sidan")
						settings.sockets.delete(ws)
					end
				end
			end
		else
			set_error("Du behöver logga in")
			redirect('/error')
		end
	end
	
	get '/register' do
		slim(:register, locals:{logged:session[:login]})
	end 

	post '/register' do
        username = params["username"]
		email = params["email"]
        password1 = params["password1"]
		password2 = params["password2"]

		test = db.execute("SELECT user_id FROM user WHERE username=?", [username])
		
		if test.empty?
			if password1 == password2
				crypt_password = BCrypt::Password.create(password1)
				
				db.execute("INSERT INTO user(username, email, crypt_password) VALUES (?,?,?)", [username, email, crypt_password])
				redirect('/')
			else
				set_error('Din lösenord är felaktigt')
				redirect('/error')
			end
		else
			set_error("Försök med ny användarnamn")
			redirect('/error')
		end
	end 

	get '/login' do
		slim(:login, locals:{logged:session[:user_id]})
	end

	post '/login' do
		db.results_as_hash = true
		login_username = params["login_email"]
		login_password = params["login_password"]
		
		result = db.execute("SELECT user_id,crypt_password FROM user WHERE username	=?", [login_username])
		# print result
		if result.empty?
			set_error('Det finns inget sådant användarnamn')
			redirect("/error")
		else
			crypt_password = result.first["crypt_password"]
			if BCrypt::Password.new(crypt_password) == login_password
				session[:user_id] = true
				session[:username] = login_username
				redirect('/')
			else
				redirect('/error')
			end
		end
	end 

	get '/profile' do
			profile = db.execute("SELECT * FROM user WHERE username =?", session[:username])
			slim(:profile, locals:{profile: profile})
	end
	
	post '/logout' do
		session[:user_id] = false
		redirect("/") 
	end

end           
