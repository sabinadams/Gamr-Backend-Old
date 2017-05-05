component accessors="true" {
	// Called by ../resources/registerController.cfc
	public function register( required struct user ){
		try{
			//Make sure the user supplied an email and that a user does not already exist with that email
			if(!user.keyExists('email') || !application._user.loadByEmail( user.email ).isNew()){
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
			if(!user.keyExists('tag') || !application._user.loadByTag( user.tag ).isNew()){
				//Return an error message if a user already has that tag
				return {
					status: application.status_code.forbidden,
					message: 'That tag is taken. Try another!'
				};
			}

			if(!user.tag.len()){
				return {
					status: application.status_code.forbidden,
					message: 'Please input a tag.'
				};
			}
			if( !user.password.len()) {
				return {
					status: application.status_code.forbidden,
					message: 'Please provide a password.'
				};
			}
			//Hashes the supplied password
			var salt = hash( generateSecretKey("AES"), "SHA-512" );
			var hashedPass = hash( user.password & salt, "SHA-512" );

			//If a first name was provided, set the first_name column for this user record
			if( user.keyExists('first_name') && len(trim(user.first_name))){
				application._user.setFirst_Name( user.first_name );
			} 
			//If a last name was provided, set the last_name column for this user record
			if( user.keyExists('last_name') && len(trim(user.last_name))){
				application._user.setLast_Name( user.last_name );
			}
			//If a description was provided, set the description column for this user record
			if( user.keyExists('description') && len(trim(user.description)) ){
				application._user.setDescription( user.description );
			} 

			//Sets all the other provided values. These aren't checked because they are required fields
			application._user.setSalt( salt );
			application._user.setEmail( user.email );
			application._user.setTag( user.tag );
			application._user.setPassword( hashedPass ); //Salt?
			application._user.setCreation_date( now() ); //now() gives a timestamp
			application._user.save();
			application._session.loadByTokenAndUser_idAndTimestamp( user.token, application._user.getID(), now() );
			application._session.save();
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
				user: {
					'ID': application._user.getID(),
					'email': user.email,
					'description': user.description,
					'first_name': user.first_name,
					'last_name': user.last_name,
					'tag': user.tag,
					'active': application._user.getActive(),
					'token': user.token,
					'logged_in': 1
				}
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
			application._user.loadByEmail( email );
			var salt = application._user.getSalt();
			//If the user exists and they are active
			if( !application._user.isNew() 
				&& application._user.getActive() 
				&& application._user.getPassword() == hash( password & salt, "SHA-512" )
			){
				//Check to see if there is a session with the provided token
				application._session.loadByTokenAndUser_id( token, application._user.getID() );

				//If the session does not exist create a new token session
				if( !application._session.isNew() ){
					//Set the timestamp of the session
					//The Token and User_ID are already set from when we tried to load the token
					application._session.setTimestamp( now() );
					application._session.save();
					//Update the user's timestamp
					application._user.setTimestamp( now() );
					application._user.save();
					//Return the user object
					return {
						user: {
							'ID': application._user.getID(),
							'email': application._user.getEmail(),
							'description': application._user.getDescription(),
							'first_name': application._user.getFirst_name(),
							'last_name': application._user.getLast_name(),
							'tag': application._user.getTag(),
							'active': application._user.getActive(),
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
							'ID': application._user.getID(),
							'email': application._user.getEmail(),
							'description': application._user.getDescription(),
							'first_name': application._user.getFirst_name(),
							'last_name': application._user.getLast_name(),
							'tag': application._user.getTag(),
							'active': application._user.getActive(),
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
			application._user.loadByID( application._session.getUser_id() );
			//If there was a matching user who is active
			if( !application._user.isNew() && application._user.getActive()) {
				//Update the user's timestamp
				application._user.setTimestamp( now() );
				//Set the logged in status to logged in
				application._user.save();
				//Update the token's timestamp
				application._session.setTimestamp( now() );
				application._session.save();
				//Return a user object so it can be placed in a request level variable for future reference
				return {
					user: {
						'ID': application._user.getID(),
						'email': application._user.getEmail(),
						'description': application._user.getDescription(),
						'first_name': application._user.getFirst_name(),
						'last_name': application._user.getLast_name(),
						'tag': application._user.getTag(),
						'active': application._user.getActive(),
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
