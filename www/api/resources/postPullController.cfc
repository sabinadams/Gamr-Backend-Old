component extends = "taffy.core.resource" taffy_uri="/postpull/{timestamp}/"{

	function get( timestamp ){

		var _postService = new services.postService();

		return representationOf( _postService.getPosts( 0, timestamp )).withStatus( 200 );

	}

}