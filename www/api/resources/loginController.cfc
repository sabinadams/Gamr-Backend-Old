component extends="taffy.core.resource" taffy_uri="/login/" {
	function post( email = "" , password = "", token = "" ){

		var user = application.auth.authenticate( email = email, password = password, token = token ).user;
		if( user.logged_in ){
			var response = {
				'full_name' : user.first_name & " " & user.last_name,
				'ID' : user.id,
				'email' : user.email,
				'logged_in' : user.logged_in,
				'token' : user.device_token, 
				'tag' :user.tag,
				'description': user.description,
				'status': application.status_code.success	
			};
		} else {
			response = {
				'status': application.status_code.forbidden,
				'message': "Invalid login."
			};
		}

		return representationOf( response ); //.withStatus( session.user.status );
	}
}