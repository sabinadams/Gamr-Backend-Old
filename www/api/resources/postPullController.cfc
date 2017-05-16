component extends = "taffy.core.resource" taffy_uri="/postpull/{timestamp}/"{

	function get( timestamp ){

		var _postService = new services.postService();

		return representationOf( _postService.postLongPull( timestamp )).withStatus( 200 );

	}

}