component extends = "taffy.core.resource" taffy_uri="/feed/responses/{index}/{postID}/{commentID}/{responseType}/" {
// lastID = 0, postID, commentID = "", responseType = ""
	function get( index = 0, postID = 0, commentID = 0, responseType = false ){
		var data = {
			index: index,
			postID: postID,
			commentID: 0,
			replies: false
		};

		if(commentID != 0 && responseType ){
			data.commentID = commentID;
			data.replies = true;
		}

		var _feedSvc = new services.feedService();
		// return representationOf( _feedSvc.getResponses(lastID , postID, commentID, responseType)).withStatus( 200 );
		return representationOf( _feedSvc.getResponses(data)).withStatus( 200 );

	}

}