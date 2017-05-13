//Posting, Commenting, Liking, Sharing, Modifying, etc...
component accessors="true" {

	//Long pulling
		//Checks for posts that are after the first post on your timeline. 
		//Returns any new posts

	public function savePost( data ) {

		var post = {
			text: data.text,
			user_ID: request.user.id,
			timestamp: now(),
			original_user: request.user.id, //May need this for sharing
			exp_count: 0,
			images: data.keyExists( 'images' ) ? data.images : [] ,
			video: data.keyExists( 'video' ) ? data.video : ''
		};

		//Check if the post data is correct (len < 601)
		if( !post.text.len() < 600 ){
			return {
				status: application.status_code.forbidden,
				message: "Posts must be 600 characters or less."
			};
		}

		//Save post data and link to user
		var postID = application.dao.insert( table = 'posts', data = post );
		post['ID'] = postID;

		//Check for images (<7)
		if( arrayLen(post.images) < 7 ){
			for( image in data.images ) {
				var imageID = application.dao.insert( table = 'images', data = { url: image } );
				application.dao.insert( table="users_to_images", data = {user_ID: request.user.id, image_ID: imageID});
				application.dao.insert( table="posts_to_images", data = {post_ID: postID, image_ID: imageID});
			}
		}
		
		//Check for video (1)
		if( post.video.len() > 0 ){
			var videoID = application.dao.insert( table = 'videos', data = { url: data.video } );
			application.dao.insert( table="users_to_videos", data = {user_ID: request.user.id, video_ID: videoID});
			application.dao.insert( table="posts_to_videos", data = {post_ID: postID, video_ID: videoID});
		}

		//Deal with mentions (Can't @mention yourself)
			//Gets all the data.mentions
			//Add a subscription to the post for the user @mentioned
			//Sends them a notification
			//The client will parse out @mentions into links to their page

		//Notify anyone who has subscribed to notifications from your posts
			//Send notifications to all people subscribed to notifications when you post

		//Deal with experience stuff

		return {
			status: application.status_code.success,
			message: "Post saved!",
			post: post
		};
	}

	public function likePost( postID ) {

		//Add like to the db
		var _likecheck = new com.database.Norm( table="post_likes", autowire = false, dao = application.dao );
		_likecheck.loadByPost_idAndUser_id( postID, request.user.id );
		var _post = new com.database.Norm( table="posts", autowire = false, dao = application.dao );
		_post.loadByID( postID );

		if(request.user.id != _post.getUser_id() ){
			if( _likecheck.isNew() ){
				_likecheck.setUser_id(request.user.id);
				_likecheck.save();
				//Notify poster you liked their post

				/* Notify any people subscribed to the post that someone liked a post they are subscribed to
				   This includes people who manually subscribed, or people who have commented on the post */

				//Notify any @mentioned people that someone liked a post they were mentioned in

				//Deal with experience stuff
				return {
					status: application.status_code.success,
					message: "You liked the post."
				}
			} else {
				application.dao.execute(
					sql="DELETE FROM post_likes WHERE post_ID = :postID AND user_ID = :userID",
					params = { postID: postID, userID: request.user.id }
				);
				return {
					status: application.status_code.success,
					message: "You un-liked the post."
				}
			}
		} else {
			return {
				status: application.status_code.forbidden,
				message: "You can't like your own post."
			};
		}
	}

	public function deletePost( postID ) {

		var _post = new com.database.Norm( table="posts", autowire = false, dao = application.dao );
		_post.loadByPost_idAndUser_id( postID, request.user.id );

		if( !_post.isNew() ) {
			var comments = application.dao.read(
				sql="SELECT * FROM comments WHERE post_ID = :postID",
				params = { postID: _post.getID() },
				returnType = "array"
			);

			// for ( comment of comments ) {

			// }

			//Get Comments
				//Delete comments
					//Delete Images, comments 2 images
					//Delete Videos, comments 2 videos
				//Delete comment likes
			//Delete Images, posts 2 images
			//Delete Videos, posts 2 videos
			//Delete post likes
		}

		//Delete @mentions
		//Delete notifications
		//Delete subscriptions

	}

	public function getPosts( index ) {

		var follows = application.dao.read( 
			sql="SELECT GROUP_CONCAT(followed_ID) as user FROM follows WHERE follower_ID = :userID",
			params = { userID: request.user.id }
		);
		var idList = ListToArray(follows.user);
    	arrayAppend(idList, val(request.user.id));

	    var posts = application.dao.read(
	        sql = "
	        	SELECT p.*, u.display_name, u.id, u.profile_pic, uoriginal.display_name, uoriginal.id,
	        	uoriginal.profile_pic, GROUP_CONCAT( DISTINCT l.user_ID ) as likes, GROUP_CONCAT( DISTINCT i.url) as images, 
	        	GROUP_CONCAT(DISTINCT v.url) as video
	        	FROM posts p
	        	LEFT JOIN post_likes l on l.post_ID = p.id
	        	LEFT JOIN users u on u.id = p.user_ID
	        	LEFT JOIN users uoriginal on uoriginal.id = p.original_user
	        	LEFT JOIN posts_to_images p2i on p2i.post_ID = p.id
	        	LEFT JOIN images i on p2i.image_ID = i.id
	        	LEFT JOIN posts_to_videos p2v on p2v.post_ID = p.id
	        	LEFT JOIN videos v on p2v.video_ID = v.id
	        	WHERE p.user_ID IN (:idList{list=true}) 
	        	GROUP BY p.ID
                ORDER BY p.timestamp DESC LIMIT :start{type='int'},20 
	        ",
	        params = {idList: idList, userID: request.user.id, start:index},
	        returnType = "array" 
	    );


		//Grabs the most recent 20 posts starting from a given index that your friends have cumulatively made
			//Images, Videos, Likes, @mentions as well

		//getComments()
		return posts;
	}	

	public function postPull( data ) {

		//Validate session/authenticity

		//Gets your friends list

		//Searches for all posts from your friends newer than a specified ID

		//getComments()

	}

}
