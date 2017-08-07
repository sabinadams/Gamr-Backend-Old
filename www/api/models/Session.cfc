//	property name="timestamp" type="date" column="timestamp" formula="now()";
component norm_persistent="true" table="sessions" extends="com.database.Norm" accessors="true" {
	property name="ID" type="numeric" fieldtype="id" generator="increment";
	property name="token" type="string" column="token";
	property name="user_ID" type="numeric" column="user_ID";
	property name="timestamp" type="date" column="timestamp";
		/* Relationships */
	// property name="users" inverseJoinColumn="user_ID" fieldType="many-to-one" fkcolumn="ID" cfc="models.User";
}