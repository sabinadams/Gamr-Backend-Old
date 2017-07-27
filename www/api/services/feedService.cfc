// Long polling eventually will manage notifications, unread pms, and timeline stuff. That doesn't have to do with this file
// but at least it's somewhere in writing


component accessors="true" {
    // Maybe don't even get responses here because it's going to the timeline preview section
    public function getFeedItems( timeIndex = "",  polling = false ){
        // - Get list of blocked accounts and accounts who block you
        // - Only grabs posts that are from users you aren't blocking and that aren't blocking you

        var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );

        // Holds the indexing query defined in the below if statements
        var indexQuery = "";
        // If a timestamp was given, query for posts before that time
        if(timeIndex != ''){ indexQuery = "AND r.timestamp  < :timeIndex"; }
        // If you are long-polling for posts, grab posts before the given timestamp
        if( polling ) { indexQuery = "AND r.timestamp > :timeIndex"; }

        var feed_items = application.dao.read(
            sql="
                SELECT 
                    r.*, 
                    u.display_name as user_name, u.id as user_ID, u.profile_pic as profile_pic, u.tag as user_tag, 
                    GROUP_CONCAT( DISTINCT l.user_ID ) as likes,
                    GROUP_CONCAT( DISTINCT a.id) as attachments
                FROM timeline_feed r 
                    LEFT JOIN timeline_feed_items_to_attachments r2a on r2a.item_ID = r.ID
                    LEFT JOIN timeline_likes l on l.item_ID = r.id
                    LEFT JOIN attachments a on r2a.attachment_ID = a.id
                    LEFT JOIN users u on u.id = r.user_ID
                WHERE post_ID = 0 AND comment_ID = 0 
                    AND (
                        r.user_ID IN (
                            SELECT followed_ID FROM follows
                            WHERE follower_ID = :userID
                        )
                        OR r.user_ID = :userID
                    )
                #indexQuery#
                GROUP BY r.ID
                ORDER BY r.timestamp DESC 
                LIMIT :limit{type='int'}
            ",
            params = { timeIndex: timeIndex, userID: request.user.id, limit: polling ? 999 : 10 },
            returnType="array"
        );
        for(var item in feed_items){
            item['comments'] = getResponses({index: 0, postID: item.ID, commentID: 0, replies: true} );
            item = formatFeedItem(item, _user);
        }
        return feed_items;
    }

    public function getSingleFeedItem( itemID ){
        var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
        var item = application.dao.read(
            sql="
                SELECT 
                    r.*, 
                    u.display_name as user_name, u.id as user_ID, u.profile_pic as profile_pic, u.tag as user_tag, 
                    GROUP_CONCAT( DISTINCT l.user_ID ) as likes,
                    GROUP_CONCAT( DISTINCT a.id) as attachments
                FROM timeline_feed r 
                    LEFT JOIN timeline_feed_items_to_attachments r2a on r2a.item_ID = r.ID
                    LEFT JOIN timeline_likes l on l.item_ID = r.id
                    LEFT JOIN attachments a on r2a.attachment_ID = a.id
                    LEFT JOIN users u on u.id = r.user_ID
                WHERE r.ID = :itemID 
            ",
            params = { itemID: itemID },
            returnType="array"
        )[1];        
        item['comments'] = [];
        return formatFeedItem(item, _user);
    }

    public function test() {
        // var user = application.dao.from(
        //     table = "users",
        //     columns = "users.ID, users.tag, users.email" 
        // ).join( 
        //     type = "LEFT", 
        //     table = "sessions", 
        //     on = "users.ID = sessions.user_ID",
        //     columns = "sessions.token as sessionToken"
        // ).groupBy(
        //     'users.ID'
        // ).where( 
        //     "users.ID", "=", 27 
        // ).returnAs('array').run();
        return {message: 'test'};
    }
    // responseType will be set by the controller, not the client
     /*
        Find a way to do indexing and take into account the fact that people could comment 
        before you go to load more, which would throw your index off
     */
    //  ------------------------> The below process should be re-thought because it's naysty <------------------------

    /*

        Index (Required): Which index to start grabbing posts from (0 will start from beginning)
        postID (Required): Root level post's ID
        commentID (Only pass if getting replies): ID of second level response
        replies (Only pass if getting replies): true if looking for replies, else getting comments with replies

    */
    // public function getResponses( index = 0, postID = 0, commentID = 0, responseType = "" ){
    public function getResponses( required struct data ){

        var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
        // Grabs based off an index (NOT TESTED)
        var startQuery = data.index != 0 ? ":index{type='int'}," : "";
        // Determines whether or not you are grabbing 3rd level responses, replies (they have a post_ID and a comment_ID)
        var typeQuery = "AND comment_ID = " & (data.replies ? ":commentID" : "0");
        // Queries for feed items based on criteria
        var responses = application.dao.read(
            sql="
                SELECT r.*, 
                    u.display_name as user_name, u.id as user_ID, u.profile_pic as profile_pic, u.tag as user_tag, 
                    GROUP_CONCAT( DISTINCT l.user_ID ) as likes,
                    GROUP_CONCAT( DISTINCT a.id) as attachments
                FROM timeline_feed r 
                    LEFT JOIN timeline_feed_items_to_attachments r2a on r2a.item_ID = r.ID
                    LEFT JOIN timeline_likes l on l.item_ID = r.id
                    LEFT JOIN attachments a on r2a.attachment_ID = a.id
                    LEFT JOIN users u on u.id = r.user_ID
                WHERE post_ID = :postID #typeQuery#
                GROUP BY r.ID
                ORDER BY r.timestamp DESC 
                LIMIT #startQuery#10
            ",
            params = {postID: data.postID, index: data.index, commentID: data.commentID},
            returnType="array"
        );

        for(var response in responses){
            response['replies'] = getResponses({index: 0, postID: data.postID, commentID: response.ID, replies: true} );
            response = formatFeedItem(response, _user);
        }
        return responses;
    }

    public function test() {
        
        var user = new com.database.Norm( dao = application.dao, table = 'users');
        user.setDynamicMappingFKConvention('user_ID');
        user.hasMany('sessions');
        user.loadByID(27);
        
        return user.getSessions().toStruct();
    }   

    public function formatFeedItem( row, _user ) {
        // Parses likes csv to an array
        row['likes'] = ListToArray(row['likes']);
        // Flag to determine whether or not you have liked the post
        row['liked'] = arrayFind(row['likes'], request.user.ID) != 0 ? true : false;
        // Gathers all the user data into a user object
        row['user'] = {
            'display_name': row.user_name,
            'ID': row.user_ID,
            'tag': row.user_tag,
            'profile_pic': row.profile_pic
        };
        StructDelete(row, 'user_name');
        StructDelete(row, 'user_ID');
        StructDelete(row, 'user_tag');
        StructDelete(row, 'profile_pic');
        StructDelete(row, 'comment_ID');
        StructDelete(row, 'post_ID');
        
        if(row.keyExists('comments')){
            row['response_count'] = arrayLen(row['comments']);
            for(var comment in row['comments']) {
                if(comment.keyExists('replies')){
                    row['response_count'] += arrayLen(comment['replies']);
                }
            }
        } else {
            row['response_count'] = 0;
        }

        // Prepares attachments object (images: 0 | gifs: 1 | videos: 2)
        var attachments = row['attachments'];
        row['attachments'] = {};

        // Populates the images array
        row.attachments['images'] = attachments.filter((attachment) => { return attachment.type == 0; });
        // Populates the gifs array
        row.attachments['gifs'] = attachments.filter((attachment) => { return attachment.type == 1; });
        // Populates the videos array
        row.attachments['videos'] = attachments.filter((attachment) => { return attachment.type == 2; });

        // Splits the text wherever there is a mention
        var mentions = REMatch('(^|\s)(@\w+)(\s|\Z)', row['text']);
        // Prepares text for @mention parsing on the client
        for(var mention in mentions){
            // Trims spaces from around the mention
            var link = Trim(mention);
            // Checks to see if the person being @mentioned is an actual user
            _user.loadByTag( Mid(link, 2, link.len()));
            // If there was a user with the tag
            if(!_user.isNew()){
                // Places UUIDs around the the mentions and turns the turns the text into a CSV with @mentions being seperated
                // into their own segments
                row['text'] = row['text'].replace(',#row.uuid & Mid(link, 2, link.len()) & row.uuid#,', mention, 'ALL' );
                row['text'] = row['text'].replace(mention, ',#row.uuid & Mid(link, 2, link.len()) & row.uuid#,', 'ALL');
            }
        }
        // Splits the text csv into an array so it can be looped through on the client
        // Might just go ahead and split text into an array here to eliminate some logic from the client
        row['text'] = ListToArray(row.text);
        return row;
    }

    public function toggleLike( itemID ){
        // Likes and unlikes posts
        var _post = new com.database.Norm( table="timeline_feed", autowire = false, dao = application.dao );
        var _like = new com.database.Norm( table="timeline_likes", autowire = false, dao = application.dao );
        _post.loadByID( itemID );
		if( !_post.isNew() && _post.getUser_id() != request.user.ID ) {
            _like.loadByUser_IDAndItem_ID(request.user.ID, itemID);
            if(_like.isNew()){
                _like.setTimestamp(now());
                _like.save();
            } else {
                application.dao.execute(
                    sql="DELETE FROM timeline_likes WHERE user_ID = :userID AND item_ID = :itemID",
                    params={userID: request.user.id, itemID: itemID}
                );
            }
            return {
                'status': application.status_code.success,
                'message': 'Liked post'
            };
        } else {
            return {
                'status': application.status_code.forbidden,
                'message': 'There was a problem with this request.'
            };
        } 
    }

    // Attachments should be uploaded seperately and their IDs should be sent instead to prevent some security issues
    // Should be renamed to saveFeedItem()
    public function savePost( data ){
        // Make sure you are allowed to mention whoever is mentioned
        var post = {
            text: data.text,
            timestamp: now(),
            creation_date: now(),
            shared: false,
            uuid: createUUID(),
            original_user: request.user.id,
            user_ID: request.user.id
        };

        if(data.keyExists('commentID')){
            post['comment_ID'] = data.commentID;
        }
        if(data.keyExists('postID')){
            post['post_ID'] = data.postID;
            var _parent_post = new com.database.Norm( table="timeline_feed", autowire = false, dao = application.dao );
            _parent_post.loadByID(data.postID);
            _parent_post.setTimestamp( now() );
            _parent_post.save();
        }
        
        var postID = application.dao.insert( table = 'timeline_feed', data = post );
        // Should return a single response in the post field
        return {
            'status': application.status_code.success,
            'message': "Posted Successfully",
            'post': getSingleFeedItem(postID)
        };
    }

    public function sharePost( postID ) {   
    }

    public function deletePost( postID ) {
        var _post = new com.database.Norm( table="timeline_feed", autowire = false, dao = application.dao );
		_post.loadByIDAndUser_id( postID, request.user.ID );

		if( !_post.isNew() ) {
            var deleteQuery = '';
            var commentCheck = _post.getPost_Id();
            var replyCheck =  _post.getComment_ID();

            if(commentCheck == 0 && replyCheck == 0){
                deleteQuery = "ID = :postID OR post_ID = :postID OR comment_ID = :postID";
            } else if (commentCheck != 0 && replyCheck == 0){
                deleteQuery = "ID = :postID OR comment_ID = :postID";
            } else if (commentCheck != 0 && replyCheck != 0){
                deleteQuery = "ID = :postID";
            }

            application.dao.execute(
                sql="DELETE FROM timeline_feed WHERE #deleteQuery#",
                params={postID: postID}
            );
            application.dao.execute(
                sql="DELETE FROM attachments WHERE ID IN (
                    SELECT attachment_ID FROM timeline_feed_items_to_attachments WHERE item_ID = :postID
                )",
                params={postID: postID}
            );
            application.dao.execute(
                sql="DELETE FROM timeline_feed_items_to_attachments WHERE item_ID = :postID",
                params={postID: postID}
            );
            application.dao.execute(
                sql="DELETE FROM timeline_likes WHERE item_ID = :postID",
                params={postID: postID}
            );

            return {
                'status': application.status_code.success,
                'message': "Posted Deleted!"
            };
        } else {
            return {
                'status': application.status_code.forbidden,
                'message': "Not authorized to make this request."
            };
        }
    }
}