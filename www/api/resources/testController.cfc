component extends = "taffy.core.resource" taffy_uri="/test/"{

	function get(){
		return representationOf( {status: application.status_code.success, message: "Test"} );
	}

}