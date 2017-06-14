component extends = "taffy.core.resource" taffy_uri="/feed/responses/{timestamp}/"{

	function get( timestamp ){
		var _postService = new services.testPostService();
		return representationOf( _postService.getFeedItems( timestamp, true )).withStatus( 200 );
	}

}