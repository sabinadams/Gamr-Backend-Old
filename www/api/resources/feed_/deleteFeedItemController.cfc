//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/feed/delete/"{ 

	function post( ID ){
		var _feedSvc = new services.feedService(); 
		return representationOf( _feedSvc.deletePost( postID = ID ) );
	}

}