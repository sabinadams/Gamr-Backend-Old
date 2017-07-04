/**
* I define relationships and preset defaults for the orders entity
**/
// component norm_persistent="true" accessors="true" table="users" extends="com.database.Norm" {

// 	public any function load(){
// 		// For convenience, we'll just pump in the dao here (pretend it lives in the application scope)
// 		setDAO( application.dao );

// 		// Define alias mappings.  This needs to happen before the entity is loaded, because the
// 		// load method needs this mapping to build the entity relationships.
// 		// setDynamicMappings({
// 		// 	"company" = "customers",
// 		// 	"users_ID" = { "table" = "users", property = "User" },
// 		// 	"orderItems" = "order_items",
// 		// 	"default_payment_terms" = "payment_terms",
// 		// 	"default_locations_ID" = { "table" = "locations", "property" = "defaultLocation" },
// 		// 	"primary_contact" =  { "table" = "contacts", "property" = "primaryContact"
// 		// });

// 		// Now load the entity, passing any args that we were given
// 		super.load( argumentCollection = arguments );

// 		// Now that the entity is loaded, we can identify any many-to-one relationships with the hasMany function
// 		this.hasMany( table = "sessions", fkcolumn = "user_ID", property = "sessions" );

// 		return this;
// 	}
// }