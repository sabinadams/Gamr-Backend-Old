//Extend the resource class and give the endpoint a URI
component extends = "taffy.core.resource" taffy_uri="/feed/save/"{ 

	function post( data ){
		var _feedSvc = new services.feedService(); 
		return representationOf( _feedSvc.savePost( data = data ) );
	}

}