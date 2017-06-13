//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/feed/save/"{ 

	function post( data ){
		var _postSvc = new services.testPostService(); 
		return representationOf( _postSvc.savePost( data = data ) );
	}

}