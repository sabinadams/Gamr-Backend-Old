component extends = "taffy.core.resource" taffy_uri="/poststest/{index}/{polling}/"{

	function get( index = "", polling = false ){
        if(index == 'start'){ index = ""; }
		var _postService = new services.testPostService();

		return representationOf( _postService.getFeedItems( index, polling )).withStatus( 200 );

	}

}