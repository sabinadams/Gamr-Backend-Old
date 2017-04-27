component extends = "taffy.core.resource" taffy_uri = "/test/" {

    function get(){
 
 		var data = application.dao.read(sql="test", returnType="array");
        return representationOf( data ).withStatus( 200 );

    }
}
