component extends = "taffy.core.resource" taffy_uri="/feed/{timestamp}/{polling}/"{

	function get( timestamp = "", polling = false ){
        if(timestamp == 'start'){ timestamp = ""; }
		var _postService = new services.testPostService();
		return representationOf( _postService.getFeedItems( timestamp, polling ) ).withStatus( 200 );
	}

}