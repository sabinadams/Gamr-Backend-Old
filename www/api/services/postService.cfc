//Posting, Commenting, Liking, Sharing, Modifying, etc...
component accessors="true" {

	/*

		getPosts()
		savePost()
		deletePost()
		longPullPosts()
		likePost()
		-------------------
		getComments()
		saveComment()
		deleteComment()
		longPullComments()
		likeComment()

	*/

	public function savePost( data ) {
		var post = {
			text: data.text,
			user_ID: request.user.id,
			timestamp: now(),
			post_date: now(),
			original_user: request.user.id, //May need this for sharing
			images: data.keyExists( 'images' ) ? data.images : [],
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
			for( var image in data.images ) {
				var imageID = application.dao.insert( table = 'images', data = { url: image } );
				application.dao.insert( table="users_to_images", data = {user_ID: request.user.id, image_ID: imageID});
				application.dao.insert( table="posts_to_images", data = {post_ID: postID, image_ID: imageID});
			}
		}

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
		_post.loadByIDAndUser_id( postID, request.user.ID );

		if( !_post.isNew() ) {
			var post_to_images = application.dao.read(
				sql="SELECT * FROM posts_to_images WHERE post_ID = :postID",
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

			application.dao.execute(
				sql="DELETE FROM post_likes WHERE post_ID = :postID",
				params = { postID: postID }
			);
			application.dao.execute(
				sql="DELETE FROM posts WHERE ID = :postID",
				params = { postID: postID }
			);

			deletePostComments(_post.getID());

			return {
				status: application.status_code.success,
				message: 'Successfully deleted post'
			};
		}

		return {
			status: application.status_code.forbidden,
			message: 'There was a problem making this request.'
		};
	}

	public function deletePostComments( postID ) {
		var comments = application.dao.read(
			sql="SELECT * FROM comments WHERE post_ID = :postID",
			params = { postID: postID },
			returnType = "array"
		);
		for(var comment in comments) {
			var commentImages = application.dao.read(
				sql="SELECT * FROM comments_to_images WHERE comment_ID = :commentID",
				params={commentID: comment.ID}
			);
			application.dao.execute(
				sql="DELETE FROM comment_likes WHERE comment_ID = :commentID",
				params = {commentID: comment.ID}
			);
			for(image in commentImages) {
				application.dao.execute(
					sql="DELETE FROM comments_to_images WHERE comment_ID = :commentID",
					params={commentID: comment.ID}
				);
				application.dao.execute(
					sql="DELETE FROM users_to_images AND image_ID = :imageID",
					params = {imageID: image.image_ID }
				);
				application.dao.execute(
					sql="DELETE FROM images WHERE ID = :imageID",
					params = {imageID: image.image_ID}
				);
			}
		}
		application.dao.execute(
			sql="DELETE FROM comments WHERE post_ID = :postID",
			params={postID: postID}
		);
	}

	public function getPosts( index = 99, timestamp = "" ) {

		var timeQuery = len(timestamp) ? 'AND p.timestamp > :lastTimestamp' : '';
		var lengthQuery = len(timestamp) ? '' : "LIMIT :start" & "{" & "type='int'" & "}" & ",10";
		var follows = application.dao.read( 
			sql="SELECT GROUP_CONCAT(followed_ID) as user FROM follows WHERE follower_ID = :userID",
			params = { userID: request.user.id }
		);
		var idList = ListToArray(follows.user);
    	arrayAppend(idList, val(request.user.id));

	    var posts = application.dao.read(
	        sql = "
				SELECT p.*, u.display_name, u.id, u.profile_pic, uoriginal.display_name, uoriginal.id, u.tag,
				uoriginal.profile_pic, GROUP_CONCAT( DISTINCT l.user_ID ) as likes, GROUP_CONCAT( DISTINCT i.url) as images,
				COUNT(DISTINCT c.ID) as comment_count
				FROM posts p
				LEFT JOIN post_likes l on l.post_ID = p.id
				LEFT JOIN users u on u.id = p.user_ID
				LEFT JOIN users uoriginal on uoriginal.id = p.original_user
				LEFT JOIN posts_to_images p2i on p2i.post_ID = p.id
				LEFT JOIN images i on p2i.image_ID = i.id
				LEFT JOIN comments c on c.post_ID = p.id
				WHERE p.user_ID IN (:idList{list=true}) #timeQuery#
				GROUP BY p.ID
				ORDER BY p.timestamp DESC #lengthQuery#
			",
	        params = {idList: idList, start:index, lastTimestamp: timestamp},
	        returnType = "array" 
	    );

	    var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
	    for( var post in posts ) {
			var likes = ListToArray(post.likes);
	    	var images = ListToArray(post.images);
			post['likes'] = arrayLen( likes );
	    	post['liked'] = likes.find(request.user.id) != 0 ? true : false;  
	    	post['images'] = [];
	    	for( var image in images ) { arrayAppend(post['images'], {'src': image}) }
	    	var mentions = REMatch('(^|\s)(@\w+)(\s|\Z)', post['text']);
	    	for(var mention in mentions){
	    		var link = Trim(mention);
	    		_user.loadByTag( Mid(link, 2, link.len()));
	    		if(!_user.isNew()){
	    			post['text'] = post['text'].replace(',#post.uuid & Mid(link, 2, link.len()) & post.uuid#,', mention, 'ALL' );
	    			post['text'] = post['text'].replace(mention, ',#post.uuid & Mid(link, 2, link.len()) & post.uuid#,', 'ALL');
	    		}
	    	}
	    	post['text'] = ListToArray(post.text);
			post['comments'] = getComments( post.ID, 0 );
			for(var i = 1; i <= arrayLen(post['comments']); i++) {
				post.comments[i]['replies'] = getComments( post.ID, 0, post.comments[i].ID, '', true);
			}
	    }
		return posts;
	}	

	public function getComments( postID, index, commentID = 0, timestamp = "", subcomment = false ) {
		 var timeQuery = len(timestamp) ? 'AND c.timestamp > :lastTimestamp' : '';
		 var commentQuery = subcomment ? 'c.comment_ID = :commentID' : 'c.comment_ID IS NULL';
		 var comments = application.dao.read(
			sql = "
				SELECT c.*, u.display_name, u.id, u.profile_pic, u.tag, GROUP_CONCAT( DISTINCT l.user_ID ) as likes, GROUP_CONCAT( DISTINCT i.url) as images  
				FROM comments c
				LEFT JOIN comment_likes l on l.comment_ID = c.id
				LEFT JOIN users u on u.id = c.user_ID
				LEFT JOIN comments_to_images c2i on c2i.comment_ID = c.id
				LEFT JOIN images i on c2i.image_ID = i.id
				WHERE c.post_ID = :postID AND #commentQuery# #timeQuery#
				GROUP BY c.ID
				ORDER BY c.timestamp DESC LIMIT :index{type='int'},10
			",
			params = { postID: postID, index: index, commentID: commentID, lastTimestamp: timestamp},
			returnType="array"
		 );
		var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
		for (var comment in comments) {
			var likes = ListToArray(comment.likes);
			var images = ListToArray(comment.images);
			comment['likes'] = arrayLen( likes );
			comment['liked'] = likes.find(request.user.id) != 0 ? true : false;  
			comment['images'] = [];
			for( var image in images ) { arrayAppend(comment['images'], {'src': image}) }
			var mentions = REMatch('(^|\s)(@\w+)(\s|\Z)', comment['text']);
			for(var mention in mentions){
				var link = Trim(mention);
				_user.loadByTag( Mid(link, 2, link.len()));
				if(!_user.isNew()){
					comment['text'] = comment['text'].replace(',#comment.uuid & Mid(link, 2, link.len()) & comment.uuid#,', mention, 'ALL' );
					comment['text'] = comment['text'].replace(mention, ',#comment.uuid & Mid(link, 2, link.len()) & comment.uuid#,', 'ALL');
				}
			}
			comment['text'] = ListToArray(comment.text);
		}
		return comments;
	}


	public function sharePost( data ) {
		//Sharing stuff
	}

	public function saveComment( data ) {

		var comment = {
			text: data.text,
			post_ID: data.postID,
			user_ID: request.user.id,
			timestamp: now(),
			exp_count: 0,
			images: data.keyExists( 'images' ) ? data.images : [] ,
			uuid: createUUID()
		};

		if(data.keyExists('commentID')) {
			comment.comment_ID = data.commentID;
		}

		//Check if the comment data is correct (len < 601)
		if( !comment.text.len() < 600 ){
			return {
				status: application.status_code.forbidden,
				message: "Comments must be 600 characters or less."
			};
		}

		//Save comment data and link to user
		var commentID = application.dao.insert( table = 'comments', data = comment );
		comment['ID'] = commentID;


		if( arrayLen(comment.images) < 7 ) {
			for( image in comment.images ) {
				var imageID = application.dao.insert( table = 'images', data = { url: image } );
				application.dao.insert( table="users_to_images", data = {user_ID: request.user.id, image_ID: imageID});
				application.dao.insert( table="comments_to_images", data = {comment_ID: commentID, image_ID: imageID});
			}
		} 

		return { status: application.status_code.success };

	}

	public function likeComment( commentID ) {
		var _likecheck = new com.database.Norm( table="comment_likes", autowire = false, dao = application.dao );
		_likecheck.loadByComment_idAndUser_id( commentID, request.user.id );
		var _comment = new com.database.Norm( table="comments", autowire = false, dao = application.dao );
		_comment.loadByID( commentID );

		if(request.user.id != _comment.getUser_id() ){
			if( _likecheck.isNew() ){
				_likecheck.save();
				 _comment.save();
				return {
					status: application.status_code.success,
					liked: true
				}
			} else {
				application.dao.execute(
					sql="DELETE FROM comment_likes WHERE comment_ID = :commentID AND user_ID = :userID",
					params = { commentID: commentID, userID: request.user.id }
				);
				return {
					status: application.status_code.success,
					liked: false
				}
			}
		} else {
			return {
				status: application.status_code.forbidden,
				message: "You can't like your own comment."
			};
		}
	}

	public function deleteComment( commentID ) {
		var _comment = new com.database.Norm( table="comments", autowire = false, dao = application.dao );
		_comment.loadByIDAndUser_id( commentID, request.user.ID );

		if( !_comment.isNew() ) {
			var comment_to_images = application.dao.read(
				sql="SELECT * FROM comments_to_images WHERE comment_ID = :commentID",
				params = { commentID: _comment.getID() },
				returnType = "array"
			);

			var comments = application.dao.read(
				sql="SELECT * FROM comments WHERE comment_ID = :commentID",
				params = { commentID: _comment.getID() },
				returnType = "array"
			);

			//Delete from these where id in array of IDs
			for( image in comment_to_images ) {
				application.dao.execute(
					sql="DELETE FROM images WHERE ID = :imageID",
					params = { imageID: image.image_ID }
				);
				application.dao.execute(
					sql="DELETE FROM comments_to_images WHERE comment_ID = :commentID AND image_ID = :imageID",
					params = { commentID: commentID, imageID: image.image_ID }
				);
				application.dao.execute(
					sql="DELETE FROM users_to_images WHERE user_ID = :userID AND image_ID = :imageID",
					params = { userID: request.user.id, imageID: image.image_ID }
				);
			}
			
			application.dao.execute(
				sql="DELETE FROM comment_likes WHERE comment_ID = :commentID",
				params = { commentID: commentID }
			);
			
			var commentTest = application.dao.read(
				sql="SELECT * FROM comments WHERE ID = :commentID",
				params={commentID: commentID},
				returnType="array"
			);

			application.dao.execute(
				sql="DELETE FROM comments WHERE ID = :commentID",
				params = { commentID: commentID }
			);

			return { status: application.status_code.success };
		}
	}

}
