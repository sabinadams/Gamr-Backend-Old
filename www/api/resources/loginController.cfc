component extends="taffy.core.resource" taffy_uri="/login/" {
	function post( email = "" , password = "", token = "" ){

		var response = application.auth.login( email = email, password = password, token = token ).user;
		
		return representationOf( response ); //.withStatus( session.user.status );
	}
}