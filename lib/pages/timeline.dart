import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapify/models/user.dart';
import 'package:snapify/pages/home.dart';
import 'package:snapify/pages/search.dart';
import 'package:snapify/widgets/header.dart';
import 'package:snapify/widgets/post.dart';
import 'package:snapify/widgets/progress.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    setPostfromFollowers();
    getTimeline();
    getFollowing();
  }

  setPostfromFollowers() async {
    QuerySnapshot following = await followingRef
        .document(widget.currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    following.documents.forEach((doc) async {
      QuerySnapshot posts = await postsRef
          .document(doc.documentID)
          .collection('userPosts')
          .getDocuments();
      posts.documents.forEach((post) async {
        // print('${post['postId']}');
        DocumentSnapshot ispost = await timelineRef
            .document(widget.currentUser.id)
            .collection('timelinePosts')
            .document(post.documentID)
            .get();
        if (!ispost.exists) {
          await timelineRef
              .document(widget.currentUser.id)
              .collection('timelinePosts')
              .document(post['postId'])
              .setData(post.data);
        }
      });
    });
    print(
        'User following count ${following.documents.map((doc) => doc.documentID)}');

    QuerySnapshot userfeedposts = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .getDocuments();

    print('Timeline was called ${userfeedposts.documents.length}');
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return buildUserPost();
    }
  }

  buildUserPost() {
    return StreamBuilder<QuerySnapshot>(
        stream: timelineRef
            .document(widget.currentUser.id)
            .collection('timelinePosts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          posts = snapshot.data.documents
              .map((doc) => Post.fromDocument(doc))
              .toList();
          return ListView(
            children: posts,
          );
        });
  }

  buildUsersToFollow() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          // remove auth user from recommended list
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30.0,
                    ),
                    SizedBox(
                      width: 8.0,
                    ),
                    Text(
                      "Users to Follow",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(children: userResults),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: header(context, isAppTitle: true),
        body: RefreshIndicator(
            onRefresh: () => getTimeline(), child: buildTimeline()));
  }
}
