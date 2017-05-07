component extends = "taffy.core.resource" taffy_uri="/emailcheck/"{

	function post( email = "" ){

		return representationOf( {'available': application._user.loadByEmail( email ).isNew()} );

	}

}