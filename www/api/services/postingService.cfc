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
			//Save images and link them to post and user 
		if( arrayLen(post.images) < 7 ){
			for( image in data.images ) {
				var imageID = application.dao.insert( table = 'images', data = { url: image } );
				application.dao.insert( table="users_to_images", data = {user_ID: request.user.id, image_ID: imageID});
				application.dao.insert( table="posts_to_images", data = {post_ID: postID, image_ID: imageID});
			}
		}
		
		//Check for video (1)
			//Save video and link to post/user
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

		//Return post data
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

	public function deletePost( data ) {
		
		//Validate session/authenticity

		//Verify post belongs to you

		//Delete post
			//Delete images
			//Delete videos
			//Delete @mentions
			//Delete notifications
			//Delete subscriptions
			//Delete Comments

	}

	public function getPosts( data ) {
		
		//Verifies your session/authenticity

		//Grabs a list of your friends' IDs

		//Grabs the most recent 20 posts starting from a given index that your friends have cumulatively made
			//Images, Videos, Likes, @mentions as well

		//getComments()

	}	

	public function postPull( data ) {

		//Validate session/authenticity

		//Gets your friends list

		//Searches for all posts from your friends newer than a specified ID

		//getComments()

	}

	public function saveComment( data ) {

		//Validate session/authenticity

		//Makes sure the post the user is commenting on exists

		//Saves the post

		//Check for image (1)
			//Save image

		//Deal with @mentions

		//Notify post subscribers

		//Notify @mentioned people

		//Notify post creator ? ^

		//Notify other commenters ? ^^

	}

	public function likeComment( data ) {

		//Validate session/authenticity

		//Makes sure the comment exists

		//Add like to the db

		//Notify poster you liked their comment

		/*
			Notify any people subscribed to the post that someone liked a comment they are subscribed to
			This includes people who manually subscribed, or people who have commented on the post
		*/

		//Notify any @mentioned people that someone liked a comment they were mentioned in
		
	}

}
