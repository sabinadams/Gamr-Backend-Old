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

	
	public function login( string email = "", string password = "", string token = "" ) {
		//Make sure the user inputted an email and password. Also makes sure a token was sent for validation
		if( email.len() && password.len() && token.len() ){
			//Makes sure there is a user with the supplied email and password
			application.getUser.loadByEmailAndPassword( email, hash( password ) );

			//If the user exists and they are active
			if( !application.getUser.isNew() && application.getUser.getActive() ){
				//Check to see if there is a session with the provided token
				application._session.loadByTokenAndUser_id( token, application.getUser.getID() );

				//If the session does not exist create a new token session
				if( !application._session.isNew() ){
					//Set the timestamp of the session
					//The Token and User_ID are already set from when we tried to load the token
					application._session.setTimestamp( now() );
					application._session.save();
					//Update the user's timestamp
					application.getUser.setTimestamp( now() );
					application.getUser.save();
					//Return the user object
					return {
						user: {
							'ID': application.getUser.getID(),
							'email': application.getUser.getEmail(),
							'description': application.getUser.getDescription(),
							'first_name': application.getUser.getFirst_name(),
							'last_name': application.getUser.getLast_name(),
							'tag': application.getUser.getTag(),
							'active': application.getUser.getActive(),
							'token': token,
							'message': "Used existing token",
							'logged_in': 1
						}
					};

				//If the session did exist
				} else {
					//Update the token's timestamp
					application._session.setTimestamp( now() );
					application._session.save();
					//Return the user object
					return {
						user: {
							'ID': application.getUser.getID(),
							'email': application.getUser.getEmail(),
							'description': application.getUser.getDescription(),
							'first_name': application.getUser.getFirst_name(),
							'last_name': application.getUser.getLast_name(),
							'tag': application.getUser.getTag(),
							'active': application.getUser.getActive(),
							'token': token,
							'message': "New token generated",
							'logged_in': 1
						}
					};
				}
			}
		}
		//If none of the above were successful, the login was not a success
		return { user: { logged_in: false } }; 	
	}

	//Authenticates all protected requests to the server
	public function authenticate( string token = "" ){
		//Tries to load a token session with the provided token
		application._session.loadByToken(token);
		//If there is a valid token session
		if( !application._session.isNew() ){
			//Find a user with an ID matching the token session's User_ID
			application.getUser.loadByID( application._session.getUser_id() );
			//If there was a matching user who is active
			if( !application.getUser.isNew() && application.getUser.getActive()) {
				//Update the user's timestamp
				application.getUser.setTimestamp( now() );
				//Set the logged in status to logged in
				application.getUser.setLogged_in( 1 );
				application.getUser.save();
				//Update the token's timestamp
				application._session.setTimestamp( now() );
				application._session.save();
				//Return a user object so it can be placed in a request level variable for future reference
				return {
					user: {
						'ID': application.getUser.getID(),
						'email': application.getUser.getEmail(),
						'description': application.getUser.getDescription(),
						'first_name': application.getUser.getFirst_name(),
						'last_name': application.getUser.getLast_name(),
						'tag': application.getUser.getTag(),
						'active': application.getUser.getActive(),
						'token': token,
						'logged_in': 1
					}
				};
			}
		}

		//If no valid session was found, the user is not logged in
		return { user: { logged_in: false } };
	}
}
