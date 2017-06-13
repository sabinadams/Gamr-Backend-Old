component extends = "taffy.core.resource" taffy_uri="/user/{tag}"{

	function get( tag ){
		var _userService = new services.userService();
		return representationOf( _userService.getUserDetails( tag )).withStatus( 200 );
	}

}