//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/savepost/"{ 

	//Handle POST requests, should accept a user object
	function post( data ){
		var _postSvc = new services.postService(); 
		return representationOf( _postSvc.saveComment( data = data ) );
	}

}