require_relative 'module.rb'
class App < Sinatra::Base
	include ChatDB
	enable:sessions
	
	set :server, 'thin'
	set :sockets, []

	# db = SQLite3::Database.new("db/table.sqlite") 

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
				# messages = db.execute("SELECT * FROM msg")
				messages = db_message() 
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
							# db.execute("INSERT INTO msg(username, message) VALUES (?, ?)", [session[:username], msg])
							db_nwmsg(session[:username], msg)
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

		# test = db.execute("SELECT user_id FROM user WHERE username=?", [username])
		test = db_reg(username)

		if test.empty?
			if password1 == password2
				crypt_password = BCrypt::Password.create(password1)
				
				# db.execute("INSERT INTO user(username, email, crypt_password) VALUES (?,?,?)", [username, email, crypt_password])
				db_reg2(username, email, crypt_password)
				redirect('/')
			else
				set_error('Ogiltig användarnamn eller lösenord')
				redirect('/error')
			end
		else
			set_error("Ogiltig användarnamn eller lösenord")
			redirect('/error')
		end
	end 

	get '/users' do
		if session[:user_id] 
			users = db_users()
			user1 = db_getid(session[:username]).join.to_i
			list = relation(user1)
			slim(:user, locals:{users: users, list:list, user1:user1})
		else
			set_error("Du behöver logga in")
			redirect('/error')
		end 
	end

	post '/users/add/:id' do
		if session[:username] != nil  
			user2 = params[:id].to_i
			user1 = db_getid(session[:username]).join.to_i
			list = relation(user1)	
			if list.include?(user2.to_s) || user1 == user2
				set_error("Ni är redanveänner")
				redirect("/error")
			else
				db_addfriend(user1, user2)
				p list
			end 
			
		
		end 
		redirect("/users")
	end
	
	# get '/friend' do
	# 	user1 = db_getid(session[:username])
	# 	relation = relation(user1)
	# end 

	get '/profile' do
		if session[:user_id] 
			profile = db_profile(session[:username])
			slim(:profile, locals:{profile: profile})
		else
			set_error("Du behöver logga in")
			redirect('/error')
		end 
	end

	get '/login' do
		slim(:login, locals:{logged:session[:user_id]})
	end

	post '/login' do
		# db.results_as_hash = true
		login_username = params["login_email"]
		login_password = params["login_password"]
		
		result = db_login(login_username) 
		# result = db.execute("SELECT user_id,crypt_password FROM user WHERE username	=?", [login_username])
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
	
	post '/logout' do
		session[:user_id] = false
		redirect("/") 
	end

end           
