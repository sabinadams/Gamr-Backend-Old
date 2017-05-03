component extends="taffy.core.api"{
	this.name = hash(getBaseTemplatePath());
	this.sessionManagement = false;
	
	//Mappings to all the folders
	this.mappings['/com'] = expandPath( '/api/com' );
    this.mappings['/taffy'] = expandPath( '/api/taffy' );
    this.mappings['/services'] = expandPath( '/api/services' );
    this.mappings['/resources'] = expandPath( '/api/resources' );

    //Request header configurations
	getPageContext().getResponse().addHeader("Access-Control-Allow-Origin","*");
 	getPageContext().getResponse().addHeader("Access-Control-Allow-Headers","Origin, Authorization, X-CSRF-Token, X-Requested-With, Content-Type, X-HTTP-Method-Override, Accept, Referrer, User-Agent");
 	getPageContext().getResponse().addHeader("Access-Control-Allow-Methods","GET, UPDATE, POST, PUT, PATCH, DELETE, OPTIONS");

 	//Taffy Framework configuration
	variables.framework = {
		reloadKey = "reboot",
		reloadPassword = "makeithappen",
		disableDashboard = false, //Change this to true to disable the Taffy Dashboard 
		disabledDashboardRedirect = "/",
		debugKey = "debugonly"
	};

	public function onApplicationStart(){
		super.onApplicationStart();
		application.baseURL = "http#cgi.server_port eq 443 ? 's' : ''#://" & cgi.server_name;
		application.supportEmail = "gamrwelcomebot@gmail.com";
		application.status_code = {
			success: 200,
			error: 401,
			forbidden: 403
		};
		// Do conditional stuff for local dev
		if( listLast( cgi.server_name, '.' ) == 'local' ){
			//Local Development Server
		}else{
			//Production Server
		}

		application.dao = new com.database.dao( dbtype = "mysql", dsn = "gamr" );
		application.auth = new services.authService();
	}

	public function onRequestStart(){
		super.onRequestStart();
	}

	public function onSessionEnd(){
		super.onSessionEnd();
	}

	function onTaffyRequest(verb, cfc, requestArguments, mimeExt, headers){
		//Checks for and stores the token from the authorization header
		if( structKeyExists( arguments.headers, 'authorization') ){
			requestArguments['token'] =  listRest( headers[ 'authorization' ], ' ' );
		}

		// Stop here if its Preflighted OPTIONS request
		if( verb == "OPTIONS" ){
			return noData().withStatus( application.status_code.success, "OK" );
		}

		// whitelist endpoints that don't require authentication
		if( cfc == "registerController"
			|| cfc == "loginController"
			// || cfc == "testController"
		){
			return true;
		}
		
		//If an authorization token was not sent, stop and send an Authentication error
        if( !structKeyExists( requestArguments, "token" ) ){
            return noData().withStatus( application.status_code.error, "Not Authenticated" );
        }

        //Look for a user with the provided token
        var user = new com.database.Norm( table = "users", autowire = false, dao = application.dao );
		user.loadByDevice_Token( requestArguments['token'] );

		//If a user with that token exists, update their timestamp
		if(!user.isNew()){
			application.dao.execute(
				sql = "UPDATE users SET timestamp = :currtime{type='timestamp'} WHERE device_token = :token",
				params = { token: requestArguments['token'], currtime: now() }
			);	
		}

        // Grab the user's MetaData using the token
        var userMetadata = application.auth.authenticate( token = requestArguments.token ).user;
        request.user = userMetaData;
        //Check the metadata for valid login flag. If the user is not logged in, 
        //return the error details stored in the metadata variable
	    if( !userMetadata.logged_in ){
	    	return representationOf(userMetadata).withStatus( application.status_code.forbidden );
	    }

	    //If all checked out, allow the user to access the resource
		return true;

	}



}
