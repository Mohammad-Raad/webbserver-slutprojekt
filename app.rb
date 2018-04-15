class App < Sinatra::Base

	#___________________NOTES_____________________
	#HUR GJORDE MAN SIDAN DYNAMISK SÅ ATT DEN LADDAR OLIKA PRODUKTER MED SAMMA LAYOUT?
	#___________________NOTES_____________________

	#enable :sessions
	use Rack::Session::Cookie,  :key => 'rack.session',
                                :expire_after => 2592000, # In seconds
                                :secret => 'kryptering'

	get('/register') do
		slim(:register)
	end

	get('/start') do
		db = SQLite3::Database.new("db/db.db")
		if session[:login]
			username = db.execute("SELECT username FROM users WHERE id=?", [session[:id]]).first.first
		else
			username=""
		end
		products = db.execute("SELECT * FROM products")
		slim(:start, locals:{products:products, username:username})
	end

	get('/saved_prod') do
		slim(:saved_prod)
	end

	get('/') do
		redirect("/start")
	end

	get('/cart') do
		db = SQLite3::Database.new("db/db.db")
		if session[:login]
			username = db.execute("SELECT username FROM users WHERE id=?", [session[:id]]).first.first
		else
			username=""
		end
		slim(:cart, locals:{username:username})
	end

	get('/product/:prod_id') do
		i = (params["prod_id"].to_s).to_i
		db = SQLite3::Database.new('db/db.db')
		if session[:login]
			username = db.execute("SELECT username FROM users WHERE id=?", [session[:id]]).first.first
		else
			username=""
		end
		prod_id=params[:prod_id]
		product= db.execute("SELECT * FROM products WHERE id=?", [prod_id]).first
		slim(:product, locals:{product:product, username:username, i:i})
	end

	post('/register') do
		db = SQLite3::Database.new('db/db.db')
		db.results_as_hash = true
		
		username = params["username"]
		password = params["password"]
		user_info= params["user_info"]
		password_confirmation = params["confirm_password"]
		
		result = db.execute("SELECT id FROM users WHERE username=?", [username])

		if result.empty?
			if password == password_confirmation
				password_digest = BCrypt::Password.create(password)
				db.execute("INSERT INTO users(username, password_digest, user_info) VALUES (?,?,?)", [username, password_digest, user_info])
				redirect('/')
			else
				set_error("Passwords don't match")
				redirect('/error')
			end
		else
			set_error("Username already exists")
			redirect('/error')
		end

	end

	post('/login') do
		db = SQLite3::Database.new('db/db.db') #Länka SQLITE
		username = params["username"] # Hämtad från register.slim, input med name="username"
		password = params["password"]
		password_crypted = db.execute("SELECT password_digest FROM users WHERE username=?", [username])
		if password_crypted == []
			password_digest = nil
		else
			password_crypted = password_crypted[0][0] # första värdet, kollar på username, andra värden är password
			password_digest = BCrypt::Password.new(password_crypted) # "Dekryptar"
		end
		if password_digest == password # om lösenordet matchar
			result = db.execute("SELECT id FROM users WHERE username=?", [username]) #Hämta ID från konton
			session[:id] = result[0][0] # id
			session[:login] = true # Är inloggad
		else
			session[:login] = false # Är INTE inloggad
		end

		redirect('/start')
	end

	get('/login') do
		slim(:login)
	end

	get('/profile/:user_id') do
		db = SQLite3::Database.new('db/db.db')
		user_id = session[:id].to_i
		if session[:login] == true #Om man har loggat in		
			begin
				products = db.execute('SELECT * FROM saved_prod WHERE user_id=?', [user_id]).first.first
				i = (params["products"].to_s).to_i
				p products
				username = db.execute('SELECT username FROM users WHERE id=?', [user_id]).first.first
				user_info = db.execute('SELECT user_info FROM users WHERE id=?', [user_id]).first.first
				product_id = db.execute("SELECT * FROM products WHERE id=?", [products])
				p product_id
			rescue SQLite3::ConstraintException
				session[:message] = "You are not logged in"
				redirect("/error")
			end
		else
			session[:message] = "You are not logged in"
			redirect("/error")
		end

		slim(:profile, locals:{product_id:product_id, username:username, user_info:user_info, i:i})
	end

	post('/delete/:id') do
		db = SQLite3::Database.new('db/db.db')
		user_id = session[:id].to_i
		id = params[:id].to_i
		db.execute("DELETE FROM saved_prod WHERE (prod_id, user_id) VALUES (?, ?)", [id, user_id])
		redirect("/profile/#{user_id}")
	end

	post('/add_favourite/:prod_id') do
		halt 403 unless session[:login]
		prod_id=params[:prod_id]
		user_id = session[:id].to_i
		db = SQLite3::Database.new('db/db.db')
		prod_name = db.execute("SELECT prod_name FROM products WHERE id=?", [prod_id]).first.first
		db.execute("INSERT INTO saved_prod (user_id, prod_id) VALUES (?, ?)", [user_id, prod_id])
		"Added #{prod_name} to your favourites!"
	end

	get('/error') do
		slim(:error, locals:{msg:session[:message]})
	end

	post('/logout') do
		session[:login] = false
		session[:id] = nil
		redirect('/start')
	end

end           
