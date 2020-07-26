import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapify/pages/home.dart';
import 'package:snapify/widgets/header.dart';
import 'package:snapify/widgets/post.dart';
import 'package:snapify/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  getPostDetail() async {
    DocumentSnapshot doc = await postsRef
        .document('106383477833364836602')
        .collection('userPosts')
        .document('732bb365-462a-42e5-9729-fbea19ee8439')
        .get();
    print(doc.reference);
  }

  @override
  Widget build(BuildContext context) {
    //getPostDetail();
    return FutureBuilder<DocumentSnapshot>(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);

        return Center(
          child: Scaffold(
            appBar: header(context, titleText: post.description),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
