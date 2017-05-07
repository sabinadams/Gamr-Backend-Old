component extends = "taffy.core.resource" taffy_uri="/tagcheck/"{

	function post( tag = "" ){

		return representationOf( {'available': application._user.loadByTag( tag ).isNew()} );

	}

}