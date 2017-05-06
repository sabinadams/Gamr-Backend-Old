component extends = "taffy.core.resource" taffy_uri="/tagcheck/{tag}/"{

	function get( tag = "" ){

		return representationOf( {'available': application._user.loadByTag( tag ).isNew()} );

	}

}