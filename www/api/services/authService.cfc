component accessors="true" {
	// Used by ../resources/registerController.cfc
	public function register( required struct user ){
		var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
		var _session = new com.database.Norm( table="sessions", autowire = false, dao = application.dao );
		try{
			//Make sure the user supplied an email and that a user does not already exist with that email
			if(!user.keyExists('email') || !_user.loadByEmail( user.email ).isNew()){
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
			if(!user.keyExists('tag') || !_user.loadByTag( user.tag ).isNew()){
				//Return an error message if a user already has that tag
				return {
					status: application.status_code.forbidden,
					message: 'That tag is taken. Try another!'
				};
			}


			//Make sure the tag has no spaces (is checked on the client but if someone bypasses client, this will prevent spaces)
			if( findNoCase(" ", user.tag, 0) ) {
				return {
					status: application.status_code.forbidden,
					message: 'Tags cannot contain spaces.'
				};
			}

			//Make sure there was actually a tag
			if(!user.tag.len()){
				return {
					status: application.status_code.forbidden,
					message: 'Please input a tag.'
				};
			}

			//Make sure there is a password
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
				_user.setFirst_Name( user.first_name );
			} 
			//If a last name was provided, set the last_name column for this user record
			if( user.keyExists('last_name') && len(trim(user.last_name))){
				_user.setLast_Name( user.last_name );
			}
			//If a description was provided, set the description column for this user record
			if( user.keyExists('description') && len(trim(user.description)) ){
				_user.setDescription( user.description );
			} 

			//Sets all the other provided values. These aren't checked because they are required fields
			_user.setSalt( salt );
			_user.setEmail( user.email );
			_user.setTag( user.tag );
			_user.setPassword( hashedPass ); //Salt?
			_user.setCreation_date( now() ); //now() gives a timestamp
			_user.setDisplay_name( user.display_name );
			_user.save();
			_session.loadByTokenAndUser_idAndTimestamp( user.token, _user.getID(), now() );
			_session.save();

			//Need to set up mail server
			var mailer = new mail();
			mailer.setTo( user.email );
			mailer.setFrom("Gamr"); //Change this to an application level variable Used application.supportEmail
			mailer.setSubject("Welcome to Gamr!");
			mailer.setType("html");
			//Create a better HTML email with a "Verify Email" feature. Maybe if your email isn't verified within a week your account will be deleted
			mailer.send(body: "<h2>Welcome to Gamr!</h2><p>Click here to verify your email address.</p><button>Verify</button>");

			//Return success message to the user
			return {
				status: application.status_code.success,
				message: "Account created!",
				user: {
					'ID': _user.getID(),
					'email': user.email,
					'description': user.description,
					'first_name': user.first_name,
					'last_name': user.last_name,
					'tag': user.tag,
					'active': 0,
					'token': user.token,
					'display_name': user.display_name,
					'profile_pic': 'http://placehold.it/200x200', //temporary
					'level': 1,
					'logged_in': 1,
					'post_count': 0,
					'exp_count': 0
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

	// Used by ../resources/loginController.cfc
	public function login( string email = "", string password = "", string token = "" ) {
		var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
		var _session = new com.database.Norm( table="sessions", autowire = false, dao = application.dao );
		//Make sure the user inputted an email and password. Also makes sure a token was sent for validation
		if( email.len() && password.len() && token.len() ){
			//Makes sure there is a user with the supplied email and password
			_user.loadByEmail( email );
			var salt = _user.getSalt();
			//If the user exists and they are active
			if( !_user.isNew() 
				&& _user.getActive() 
				&& _user.getPassword() == hash( password & salt, "SHA-512" )
			){
				var _userService = new services.userService();
				var postCount = _userService.getUserPostCount( _user.getID() );

				//Check to see if there is a session with the provided token
				_session.loadByTokenAndUser_id( token, _user.getID() );

				//If the session does not exist create a new token session
				if( !_session.isNew() ){
					//Set the timestamp of the session
					//The Token and User_ID are already set from when we tried to load the token
					_session.setTimestamp( now() );
					_session.save();
					//Update the user's timestamp
					_user.setTimestamp( now() );
					_user.save();
					//Return the user object
					return {
						user: {
							'ID': _user.getID(),
							'email': _user.getEmail(),
							'description': _user.getDescription(),
							'first_name': _user.getFirst_name(),
							'last_name': _user.getLast_name(),
							'tag': _user.getTag(),
							'active': _user.getActive(),
							'exp_count': _user.getExp_count(),
							'level': _user.getLevel(),
							'display_name': _user.getDisplay_name(),
							'profile_pic': _user.getProfile_pic(),
							'token': token,
							'post_count': postCount,
							'message': "Used existing token",
							'logged_in': 1
						}
					};

				//If the session did exist
				} else {
					//Update the token's timestamp
					_session.setTimestamp( now() );
					_session.save();
					//Return the user object
					return {
						user: {
							'ID': _user.getID(),
							'email': _user.getEmail(),
							'description': _user.getDescription(),
							'first_name': _user.getFirst_name(),
							'last_name': _user.getLast_name(),
							'tag': _user.getTag(),
							'active': _user.getActive(),
							'exp_count': _user.getExp_count(),
							'level': _user.getLevel(),
							'display_name': _user.getDisplay_name(),
							'profile_pic': _user.getProfile_pic(),
							'token': token,
							'post_count': postCount,
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
		var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
		var _session = new com.database.Norm( table="sessions", autowire = false, dao = application.dao );
		//Tries to load a token session with the provided token
		_session.loadByToken(token);
		//If there is a valid token session
		if( !_session.isNew() ){
			//Find a user with an ID matching the token session's User_ID
			_user.loadByID( _session.getUser_id() );
			//If there was a matching user who is active
			if( !_user.isNew() && _user.getActive()) {
				//Update the user's timestamp
				_user.setTimestamp( now() );
				//Set the logged in status to logged in
				_user.save();
				//Update the token's timestamp
				_session.setTimestamp( now() );
				_session.save();
				//Return a user object so it can be placed in a request level variable for future reference
				return {
					user: {
						'ID': _user.getID(),
						'email': _user.getEmail(),
						'description': _user.getDescription(),
						'first_name': _user.getFirst_name(),
						'last_name': _user.getLast_name(),
						'tag': _user.getTag(),
						'active': _user.getActive(),
						'display_name': _user.getDisplay_name(),
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
