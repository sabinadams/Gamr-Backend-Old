component extends = "taffy.core.resource" taffy_uri="/register/"{

	function post( user ){
		return representationOf( application.auth.register( user = user ) );
	}

}