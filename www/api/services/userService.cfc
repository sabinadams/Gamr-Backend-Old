//Posting, Commenting, Liking, Sharing, Modifying, etc...
component accessors="true" {

	public function getUserDetails( tag ) {

		var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
		_user.loadByTag( tag );
		if(!_user.isNew()){
			var user = {
				'ID': _user.getID(),
				'description': _user.getDescription(),
				'tag': _user.getTag(),
				'exp_count': _user.getExp_count(),
				'level': _user.getLevel(),
				'display_name': _user.getDisplay_name(),
				'profile_pic': _user.getProfile_pic(),
				'self':  _user.getID() == request.user.id ? true : false,
				'post_count': getUserPostCount( _user.getID() )
			};
			
			return user;
		} else {
			return {
				status: application.status_code.error,
				message: 'User not found.'
			};
		}
		
	}

	public function getUserPostCount( userID ) {
		return application.dao.read(sql=
			"SELECT COUNT(*) as postCount FROM timeline_feed WHERE user_ID = :userID",
			params = {userID: userID}
		).postCount;
	}

}
