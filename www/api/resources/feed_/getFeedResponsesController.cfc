component extends = "taffy.core.resource" taffy_uri="/feed/responses/{timestamp}/"{

	function get( timestamp ){
		var _feedSvc = new services.feedService();
		return representationOf( _feedSvc.getFeedItems( timestamp, true )).withStatus( 200 );
	}

}