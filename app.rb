require_relative 'module_sqlite3_funktioner.rb'

class App < Sinatra::Base

	#___________________NOTES_____________________
	#ska man skapa kundvagn???
	#___________________NOTES_____________________

	use Rack::Session::Cookie,  :key => 'rack.session',
                                :expire_after => 2592000, # In seconds
                                :secret => 'kryptering'
	include Sqlite3_koder
	get('/register') do
		slim(:register)
	end

	get('/start') do
		id = session[:id]
		username = show_username(id)
		products = load_products()
		slim(:start, locals:{products:products, username:username})
	end

	get('/saved_prod') do
		slim(:saved_prod)
	end

	get('/') do
		redirect("/start")
	end

	get('/cart') do
		id = session[:id]
		username = show_username(id)
		slim(:cart, locals:{username:username})
	end

	get('/product/:prod_id') do
		i = (params["prod_id"].to_s).to_i
		id = session[:id]
		username = show_username(id)
		prod_id = params[:prod_id]
		product = show_specific_product(prod_id)
		slim(:product, locals:{product:product, username:username, i:i})
	end

	post('/register') do
		
		username = params["username"]
		
		result = registering_user_confirmation(username)

		if result.empty?
			redirect(check_login(params))
		else
			session[:message] = "Username already exists"
			redirect('/error')
		end

	end

	post('/login') do
		login_check()

		redirect('/start')
	end

	get('/login') do
		slim(:login)
	end

	get('/profile/:user_id') do
		db = SQLite3::Database.new('db/db.db')
		user_id = session[:id].to_i
		if session[:login] == true #Om man har loggat in
			username = show_username(user_id)
			user_info = load_user_information(user_id)
			products = (show_favourite_products(user_id))[0]
			
		else
			session[:message] = "You are not logged in"
			redirect("/error")
		end

		slim(:profile, locals:{products:products, username:username, user_info:user_info})
	end

	post('/delete/:id') do
		user_id = session[:id].to_i
		id = params[:id].to_i
		delete_product(id, user_id)
		redirect("/profile/#{user_id}")
	end

	post('/add_favourite/:prod_id') do
		halt 403 unless session[:login]
		prod_id=params[:prod_id]
		user_id = session[:id].to_i
		prod_name = select_the_product_to_favourite(prod_id)
		adding_product_to_favourite(user_id, prod_id)
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
