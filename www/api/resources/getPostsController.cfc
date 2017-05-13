component extends = "taffy.core.resource" taffy_uri="/posts/{index}/"{

	function get( index ){

		var _postService = new services.postService();

		return representationOf( _postService.getPosts( index ));

	}

}