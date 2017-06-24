component norm_persistent="true" table="users" extends="com.database.Norm" {
    
    this.hasMany( table = "sessions", fkcolumn = "user_ID", property = "sessions" );
}