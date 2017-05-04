//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/register/"{ 

	//Handle POST requests, should accept a user object
	function post( user ){

		/********************************************************************************
			We might do all of the object validation here to ensure all the required data 
			was provided. Would clean up the service
		*********************************************************************************/

		return representationOf( application.auth.register( user = user ) );
	}

}