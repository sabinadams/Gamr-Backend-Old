component extends = "taffy.core.resource" taffy_uri="/emailcheck/{email}/"{

	function get( email = "" ){

		return representationOf( {'available': application._user.loadByEmail( email ).isNew()} );

	}

}