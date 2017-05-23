//Posting, Commenting, Liking, Sharing, Modifying, etc...
component accessors="true" {

	//Long pulling
		//Checks for posts that are after the first post on your timeline. 
		//Returns any new posts

	public function savePost( data ) {
		// Should only have a video or images. Not both
		var post = {
			text: data.text,
			user_ID: request.user.id,
			timestamp: now(),
			post_date: now(),
			original_user: request.user.id, //May need this for sharing
			exp_count: 0,
			images: data.keyExists( 'images' ) ? data.images : [] ,
			video: data.keyExists( 'video' ) ? data.video : '',
			uuid: createUUID()
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
			message: "Post saved!"
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
				 _post.save();
				return {
					status: application.status_code.success,
					liked: true,
					message: "You liked the post."
				}
			} else {
				application.dao.execute(
					sql="DELETE FROM post_likes WHERE post_ID = :postID AND user_ID = :userID",
					params = { postID: postID, userID: request.user.id }
				);
				return {
					status: application.status_code.success,
					liked: false,
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
			var post_to_images = application.dao.read(
				sql="SELECT * FROM posts_to_images WHERE post_ID = :postID",
				params = { postID: _post.getID() },
				returnType = "array"
			);

			var post_to_videos = application.dao.read(
				sql="SELECT * FROM posts_to_videos WHERE post_ID = :postID",
				params = { postID: _post.getID() },
				returnType = "array"
			);

			//Delete from these where id in array of IDs
			for( image in post_to_images ) {
				application.dao.execute(
					sql="DELETE FROM images WHERE ID = :imageID",
					params = { imageID: image.image_ID }
				);
				application.dao.execute(
					sql="DELETE FROM posts_to_images WHERE post_ID = :postID AND image_ID = :imageID",
					params = { postID: postID, imageID: image.image_ID }
				);
				application.dao.execute(
					sql="DELETE FROM users_to_images WHERE user_ID = :userID AND image_ID = :imageID",
					params = { userID: request.user.id, imageID: image.image_ID }
				);
			}
			//Delete from these where id in array of IDs
			for( video in post_to_videos ) {
				application.dao.execute(
					sql="DELETE FROM videos WHERE ID = :videoID",
					params = { videoID: video.video_ID }
				);
				application.dao.execute(
					sql="DELETE FROM posts_to_videos WHERE video_ID = :videoID AND post_ID = :postID",
					params = { postID: postID, videoID: video.video_ID }
				);
				application.dao.execute(
					sql="DELETE FROM users_to_videos WHERE video_ID = :videoID AND user_ID = :userID",
					params = { userID: request.user.id, videoID: video.video_ID }
				);
			}

			application.dao.execute(
				sql="DELETE FROM post_likes WHERE post_ID = :postID",
				params = { postID: postID }
			);
			application.dao.execute(
				sql="DELETE FROM posts WHERE ID = :postID",
				params = { postID: postID }
			);

			var comments = application.dao.read(
				sql="SELECT * FROM comments WHERE post_ID = :postID",
				params = { postID: _post.getID() },
				returnType = "array"
			);
			// for ( comment of comments ) {
					//commentService.deleteComment(comment.ID)
					//Get Comments
						//Delete comments
							//Delete Images, comments 2 images
							//Delete Videos, comments 2 videos
						//Delete comment likes
						//Delete Notifications
			// }
			
			// Delete Notifications
		}

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
	        	COUNT(DISTINCT c.ID) as comment_count,
	        	GROUP_CONCAT(DISTINCT v.url) as video
	        	FROM posts p
	        	LEFT JOIN post_likes l on l.post_ID = p.id
	        	LEFT JOIN users u on u.id = p.user_ID
	        	LEFT JOIN users uoriginal on uoriginal.id = p.original_user
	        	LEFT JOIN posts_to_images p2i on p2i.post_ID = p.id
	        	LEFT JOIN images i on p2i.image_ID = i.id
	        	LEFT JOIN posts_to_videos p2v on p2v.post_ID = p.id
	        	LEFT JOIN videos v on p2v.video_ID = v.id
	        	LEFT JOIN comments c on c.post_ID = p.id
	        	WHERE p.user_ID IN (:idList{list=true}) 
	        	GROUP BY p.ID
                ORDER BY p.timestamp DESC LIMIT :start{type='int'},10 
	        ",
	        params = {idList: idList, userID: request.user.id, start:index},
	        returnType = "array" 
	    );
	    var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
	    for( post in posts ) {
	    	var likes = ListToArray(post.likes); 
	    	post['liked'] = likes.find(request.user.id) != 0 ? true : false;  
	    	post['likes'] = arrayLen( likes );
	    	post['images'] = ListToArray(post.images);
	    	//Get the comments
	    	post['comments']  = [];
	    	var mentions = REMatch('(@\w+)(\s|\Z)', post['text']);
	    	for(mention in mentions){
	    		_user.loadByTag( Mid(mention, 2, mention.len()) );
	    		if(!_user.isNew()){
	    			post['text'] = post['text'].replace(',#post.uuid#<a href="/user/#Mid(mention, 2, mention.len())#"> #mention# </a>#post.uuid#,', mention, 'ALL' );
	    			post['text'] = post['text'].replace(mention, ',#post.uuid#<a href="/user/#Mid(mention, 2, mention.len())#"> #mention# </a>#post.uuid#,', 'ALL');
	    		}
	    	}
	    	post['text'] = ListToArray(post.text);
	    }

		//Grabs the most recent 20 posts starting from a given index that your friends have cumulatively made
			//Images, Videos, Likes, @mentions as well

		return posts;
	}	

	public function sharePost( data ) {

	}

	public function postLongPull( lastTimestamp ) {
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
	        	COUNT(DISTINCT c.ID) as comment_count,
	        	GROUP_CONCAT(DISTINCT v.url) as video
	        	FROM posts p
	        	LEFT JOIN post_likes l on l.post_ID = p.id
	        	LEFT JOIN users u on u.id = p.user_ID
	        	LEFT JOIN users uoriginal on uoriginal.id = p.original_user
	        	LEFT JOIN posts_to_images p2i on p2i.post_ID = p.id
	        	LEFT JOIN images i on p2i.image_ID = i.id
	        	LEFT JOIN posts_to_videos p2v on p2v.post_ID = p.id
	        	LEFT JOIN videos v on p2v.video_ID = v.id
	        	LEFT JOIN comments c on c.post_ID = p.id
	        	WHERE p.user_ID IN (:idList{list=true}) AND p.timestamp > :lastTimestamp
	        	GROUP BY p.ID
                ORDER BY p.timestamp DESC 
	        ",
	        params = {idList: idList, userID: request.user.id, lastTimestamp:lastTimestamp},
	        returnType = "array" 
	    );

    	for( post in posts ) {
	    	var likes = ListToArray(post.likes); 
	    	post['liked'] = likes.find(request.user.id) != 0 ? true : false;  
	    	post['likes'] = arrayLen( likes );  
	    	//Get the comments
	    	post['comments']  = [];
	    	post['images'] = ListToArray(post.images);
	    	var mentions = REMatch('(@\w+)(\s|\Z)', post['text']);
	    	for(mention in mentions){
	    		_user.loadByTag( Mid(mention, 2, mention.len()) );
	    		if(!_user.isNew()){
	    			post['text'] = post['text'].replace(',#post.uuid#<a href="/user/#Mid(mention, 2, mention.len())#"> #mention# </a>#post.uuid#,', mention, 'ALL' );
	    			post['text'] = post['text'].replace(mention, ',#post.uuid#<a href="/user/#Mid(mention, 2, mention.len())#"> #mention# </a>#post.uuid#,', 'ALL');
	    		}
	    	}
	    	post['text'] = ListToArray(post.text);
	    }
		//Gets your friends list

		//Searches for all posts from your friends newer than a specified ID

		//getComments()

		return posts;
	}

}
