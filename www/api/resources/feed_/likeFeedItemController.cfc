component extends = "taffy.core.resource" taffy_uri="/feed/like/"{

	function post( itemID ){
		var _feedSvc = new services.feedService();
		return representationOf( _feedSvc.toggleLike( itemID ) ).withStatus( 200 );
	}

}