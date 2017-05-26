component extends = "taffy.core.resource" taffy_uri="/deletepost/"{

	function post( postID ){

		var _postService = new services.postService();

		return representationOf( _postService.deletePost( postID )).withStatus( 200 );

	}

}