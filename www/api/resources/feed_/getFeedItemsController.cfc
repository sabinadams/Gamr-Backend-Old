component extends = "taffy.core.resource" taffy_uri="/feed/{timestamp}/{polling}/"{

	/*
		Grab Posts for initial timeline: {
			timestamp: "start"
			polling: false
		}

		Grab Posts starting from an index: {
			timestamp: TIMESTAMP (Timestamp of last post you loaded on the client)
			polling: false
		}

		Polling for new posts (posts that happened after the first post you loaded): {
			timestamp: TIMESTAMP (Timestamp of first post you loaded)
			polling: true
		}
	*/
	function get( timestamp = "", polling = false ){
        if(timestamp == 'start'){ timestamp = ""; }
		var _postService = new services.testPostService();
		return representationOf( _postService.getFeedItems( timestamp, polling ) ).withStatus( 200 );
	}

}