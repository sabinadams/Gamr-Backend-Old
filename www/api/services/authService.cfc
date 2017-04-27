component accessors="true" {

	//Role, Version, Access Level, Token Creation/Decryption stuff goes here in init() function

	public function register( required struct user ){
		//Register Function
		//Safely and validly create user. Then email a welcome message to user. 
		//See AQConnect's register function for reference
	}

	public function authenticate( string email = "", string password = "", string token = "" ){
		// If a token was passed in, try to load the user associated with it.
		if( len( trim( token ) ) && token != "null" ){
			var user = application.dao.read(
				sql = "
					SELECT
						`ID`,
					    `email`,
					    `active`,
					    `first_name`,
					    `last_name`,
					    `device_token`,
					    1 as isLoggedIn,
					    200 as statusCode
					    FROM users
						WHERE device_token = :token
						AND active = 1
				",
				params = { token: token },
				returnType = "array"
			);
		}
		if( !isDefined( 'user' ) || !user.len() ){ 

			var user = application.dao.read(
				sql = "
					SELECT
						`ID`,
					    `email`,
					    `active`,
					    `first_name`,
					    `last_name`,
					    `device_token`,
					    1 as isLoggedIn,
					    200 as statusCodes
					    FROM users
					WHERE email = :email
					AND password = :password
					AND active = 1
				",
				params = { email: email, password: hash( password ) },
				returnType = "array"
			);
		}
		
		if( user.len() ){
			application.dao.execute(
				sql = "UPDATE users SET device_token = :token, logged_in = 1 WHERE ID = :userId",
				params = { token:token, userId:user[ 1 ].id, currtime: now() }
			);
			// send back the new token to match the client's
			user[ 1 ].device_token = token;

			return { "user": user[ 1 ], "success": true };
		}

		return { "user": { "isLoggedIn": 0, "status": "Login Failed", "statusCode": 401, "message": "Not authorized to access requested page.  Please log in and try again." }, "success": false, "status": 401 };
	}

}
