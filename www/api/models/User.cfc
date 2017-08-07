// //	property name="timestamp" type="date" column="timestamp" formula="now()";
// component norm_persistent="true" table="users" extends="com.database.Norm" accessors="true" {

// 	property name="ID" type="numeric" fieldtype="id" generator="increment";
// 	property name="display_name" type="string" column="display_name";
// 	property name="first_name" type="string" column="first_name";
// 	property name="last_name" type="string" column="last_name";
//     property name="email" type="string" column="email";
//     property name="password" type="string" column="password";
//     property name="salt" type="string" column="salt";
//     property name="active" type="numeric" column="active";
//     property name="access_level" type="numeric" column="access_level";
//     property name="creation_date" type="date" column="creation_date";
// 	property name="timestamp" type="date" column="timestamp";
//     property name="reset_token" type="string" column="reset_token";
// 	property name="reset_timestamp" type="date" column="reset_timestamp";
// 	property name="tag" type="string" column="tag";
// 	property name="description" type="string" column="description";
// 	property name="profile_pic" type="string" column="profile_pic";
// 	property name="banner_pic" type="string" column="banner_pic";
// 	property name="exp_count" type="numeric" column="exp_count";
// 	property name="level" type="numeric" column="level";


// 	/* Relationships */
// 	property name="sessions" type="array" fieldType="one-to-many" singularname="session" fkcolumn="user_ID" cfc="models.Session";

// 	public string function getFullName(){
// 		return variables.first_name & " " & variables.last_name;
// 	}
// }
component accessors="true" output="false" table="users" extends="com.database.Norm" {
	property name="sessions" type="array" fieldType="one-to-many" singularname="session" fkcolumn="user_ID" cfc="models.Session";

	public any function load(){
		// For convenience, we'll just pump in the dao here (pretend it lives in the application scope)
		setDAO( application.dao );

		// Now load the entity, passing any args that we were given
		super.load( argumentCollection = arguments );

		// Now that the entity is loaded, we can identify any many-to-one relationships with the hasMany function
		//this.hasMany( table = "sessions", fkcolumn="user_ID", property = "sessions" );

		return this;
	}
}