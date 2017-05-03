component accessors="true" {
	// Called by ../resources/registerController.cfc
	public function register( required struct user ){
		try{
			//Holds the ORM model for the users table
			var newUser = new com.database.Norm( table="users", autowire = false, dao = application.dao);

			//Make sure the user supplied an email and that a user does not already exist with that email
			if(!user.keyExists('email') || !newUser.loadByEmail( user.email ).isNew()){
				//Return error message if a user already has that email
				return {
					status: application.status_code.forbidden,
					message: 'An account is already registered with that email.'
				};
			} else {
				//Checks to make sure the email address provided is valid
				if(!isValid("email", user.email)){
					//Returns an error if the email is improperly formatted
					return {
						status: application.status_code.forbidden,
						message: "Please use a valid email address.", 
					};
				}
			}

			//Make sure the user supplied an tag and that a user does not already exist with that tag
			if(!user.keyExists('tag') || !newUser.loadByTag( user.tag ).isNew()){
				//Return an error message if a user already has that tag
				return {
					status: application.status_code.forbidden,
					message: 'That tag is taken. Try another!'
				};
			}

			//Hashes the supplied password
			var hashedPass = hash(user.password);

			//If a first name was provided, set the first_name column for this user record
			if( user.keyExists('first_name') && len(trim(user.first_name))){
				newUser.setFirst_Name( user.first_name );
			} 
			//If a last name was provided, set the last_name column for this user record
			if( user.keyExists('last_name') && len(trim(user.last_name))){
				newUser.setLast_Name( user.last_name );
			}
			//If a description was provided, set the description column for this user record
			if( user.keyExists('description') && len(trim(user.description)) ){
				newUser.setDescription( user.description );
			} 

			//Sets all the other provided values. These aren't checked because they are required fields
			newUser.setEmail( user.email );
			newUser.setPassword( hashedPass ); //Salt?
			newUser.setTag( user.tag );
			newUser.setCreation_date( now() ); //now() gives a timestamp
			newUser.save();

			//Need to set up mail server
			var mailer = new mail();
			mailer.setTo( user.email );
			mailer.setFrom("Gamr"); //Change this to an application level variable called application.supportEmail
			mailer.setSubject("Welcome to Gamr!");
			mailer.setType("html");
			//Create a better HTML email with a "Verify Email" feature. Maybe if your email isn't verified within a week your account will be deleted
			mailer.send(body: "<h2>Welcome to Gamr!</h2><p>Click here to verify your email address.</p><button>Verify</button>");

			//Return success message to the user
			return {
				status: application.status_code.success,
				message: "Account created!",
			};
		} catch ( any e ) {
			//Upon any errors we didn't account for, return this message
			return {
				status: application.status_code.error,
				message: "There was a problem with the request. Please try again. If the problem persists please contact support at #application.supportEmail#", //Need to add a real email address.
				error: e
			};
		}
	}

	// Handles authentication and login functionality
	public function authenticate( string email = "", string password = "", string token = "" ){
		// Authenticate a request by token
		if( len( trim( token ) ) && token != "null" ){
			var user = application.dao.read(
				sql = "
					SELECT ID, email, description, first_name, last_name, tag, active, device_token, 1 as logged_in, 200 as statusCode
					FROM users WHERE device_token = :token AND active = 1
				",
				params = { token: token },
				returnType = "array"
			);
		}

		//Authenticates with a login
		if( !isDefined( 'user' ) || !user.len() ){ 
			var user = application.dao.read(
				sql = "
					SELECT ID, email, description, first_name, last_name, tag, active, device_token, 1 as logged_in, 200 as statusCodes
					FROM users WHERE email = :email AND password = :password AND active = 1
				",
				params = { email: email, password: hash( password ) },
				returnType = "array"
			);
		}
		
		//Updates the user's token upon log in
		if( user.len() ){
			application.dao.execute(
				sql = "UPDATE users SET device_token = :token, logged_in = 1 WHERE ID = :id",
				params = { token:token, id:user[ 1 ].id, currtime: now() }
			);
			// send back the new token to match the client's
			user[ 1 ].device_token = token;

			return { user: user[ 1 ]};
		}

		return { user: {logged_in: false}};
	}

}
