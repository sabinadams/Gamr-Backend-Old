//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/register/"{ 

	//Handle POST requests, should accept a user object
	function post( user ){

		/********************************************************************************
			We might do all of the object validation here to ensure all the required data 
			was provided. Would clean up the service
		*********************************************************************************/

		// application.auth is a global reference to the authService.cfc file in services
		// We could have also done this (and in all cases except for functions in the authService file we will do the below method):
		
		/********************************************************************************
			var _authService = new services.authService();
			return representationOf( _authService.register( user ));	
		*********************************************************************************/

		return representationOf( application.auth.register( user = user ) );
	}

}