component extends = "taffy.core.resource" taffy_uri="/feed/{itemID}/"{

	function get( itemID ){
		var _feedSvc = new services.feedService();
		return representationOf( _feedSvc.getSingleFeedItem( itemID ) ).withStatus( 200 );
	}

}