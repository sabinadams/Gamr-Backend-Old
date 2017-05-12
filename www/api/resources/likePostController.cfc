//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/likepost/"{ 

	//Handle POST requests, should accept a user object
	function post( postID ){
		var _postSvc = new services.postService(); 
		return representationOf( _postSvc.likePost( postID = postID ) );
	}

}