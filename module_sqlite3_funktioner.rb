module Sqlite3_koder

    def db_connect()
        return SQLite3::Database.new("db/db.db")
    end

    def show_username(id)
        db = db_connect()
        if session[:login]
            username = db.execute("SELECT username FROM users WHERE id=?", id).first.first
        else
            username=""
        end
        return username
    end

    def load_products()
        db = db_connect()
        products = db.execute("SELECT * FROM products")
        return products
    end

    def show_specific_product(prod_id)
        db = db_connect()
        product = db.execute("SELECT * FROM products WHERE id=?", [prod_id]).first
        return product
    end

    def registering_user_confirmation(username)
        db = db_connect()
        db.results_as_hash = true
        result = db.execute("SELECT id FROM users WHERE username=?", [username])
        return result
    end

    def check_login(params)
        db = db_connect()
        username = params["username"]
		password = params["password"]
		user_info= params["user_info"]
		password_confirmation = params["confirm_password"]
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password_digest, user_info) VALUES (?,?,?)", [username, password_digest, user_info])
            url = '/'
        else
            session[:message] = "Passwords don't match"
            url = '/error'
        end
        return url
    end


    def login_check()
        db = db_connect()
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
    end

    def load_user_information(user_id)
        db = db_connect()
        user_information = db.execute('SELECT user_info FROM users WHERE id=?', [user_id]).first.first
        return user_information
    end

    def show_favourite_products(user_id)
        db = db_connect()
        array_with_multple_objects = []
        saved_products = []
        products = []
        begin
            saved_products = (db.execute('SELECT * FROM saved_prod WHERE user_id=?', [user_id]))
            if saved_products.size() > 0
                saved_products.each do |saved_product|
                    product_id = saved_product[1]
                    products.push(db.execute("SELECT * FROM products WHERE id=?", [product_id])).first
                end
                array_with_multple_objects.push(products.compact)
            end
        rescue SQLite3::ConstraintException
            session[:message] = "You are not logged in"
            redirect_variable = redirect("/error")
            array_with_multple_objects.push(redirect_variable)
            return array_with_multple_objects[1]
        end
        return array_with_multple_objects
    end

    def delete_product(id, user_id)
        db = db_connect()
        db.execute("DELETE FROM saved_prod WHERE prod_id IS ? AND user_id IS ?", [id, user_id])
    end

    def select_the_product_to_favourite(prod_id)
        db = db_connect()
        prod_name = db.execute("SELECT prod_name FROM products WHERE id=?", [prod_id]).first.first
        return prod_name
    end

    def adding_product_to_favourite(user_id, prod_id)
        db = db_connect()
        db.execute("INSERT INTO saved_prod (user_id, prod_id) VALUES (?, ?)", [user_id, prod_id])
    end
end