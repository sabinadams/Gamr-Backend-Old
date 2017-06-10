//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/savepostteset/"{ 

	//Handle POST requests, should accept a user object
	function post( data ){
		var _postSvc = new services.testPostService(); 
		return representationOf( _postSvc.savePost( data = data ) );
	}

}