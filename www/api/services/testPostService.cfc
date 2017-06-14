// Long polling eventually will manage notifications, unread pms, and timeline stuff. That doesn't have to do with this file
// but at least it's somewhere in writing

// Feed Items Structure
    /*
        Posts would have: post_ID = null, comment_ID = null
        Comments would have: post_ID = p.id, comment_ID = null
        Replies would have: post_ID = p.id, comment_ID = c.id
    */

// Attachments Structure
    /*
        All "attachments" would have a "type" flag: 
            0 = image 
            1 = gif
            2 = video
    */

component accessors="true" {

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
            item['comments'] = getResponses(0, item.ID );
            item = formatFeedItem(item, _user);
        }
        return feed_items;
    }

    // responseType will be set by the controller, not the client
     /*
        Find a way to do indexing and take into account the fact that people could comment 
        before you go to load more, which would throw your index off
     */
    //  This process should be re-thought
    public function getResponses( lastID = 0, postID, commentID = "", responseType = "" ){
        var _user = new com.database.Norm( table="users", autowire = false, dao = application.dao );
        // Will query for comments that are 2nd level (they have no comment_ID set)
        var typeQuery = "AND comment_ID = 0";
        // Grabs based off an index (NOT TESTED)
        var startQuery = lastID != 0 ? ":index{type='int'}," : "";
        // Determines whether or not you are grabbing 3rd level responses, replies (they have a post_ID and a comment_ID)
        if( responseType == "replies" ){ typeQuery = "AND comment_ID = :commentID"; } 
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
            params = {postID: postID, lastID: lastID, commentID: commentID},
            returnType="array"
        );

        for(var response in responses){
            if( responseType != 'replies'){
                response['replies'] = getResponses(0, postID, response.ID, "replies" );
            }
            response = formatFeedItem(response, _user);
        }
        return responses;
    }


    public function formatFeedItem( row, _user ) {
        // Parses likes csv to an array
        row['likes'] = row['likes'].filter((like) => { return like.user_ID; });
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
        // Flag to determine whether or not you have liked the post
        row['liked'] = row['likes'].find(request.user.id) != 0 ? true : false;  

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
        }

        application.dao.insert( table = 'timeline_feed', data = post );

        return {
            status: application.status_code.success,
            message: "Posted Successfully"
        };
    }

    public function sharePost( postID ) {
        
    }
}