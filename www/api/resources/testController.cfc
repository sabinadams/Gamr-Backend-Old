component extends = "taffy.core.resource" taffy_uri="/test/"{

	function get(){

		return representationOf( request.user );

	}

}