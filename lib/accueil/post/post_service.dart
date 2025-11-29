import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  static PostService get instance => _instance;

  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 🔥 STREAM : un seul post
  // ---------------------------------------------------------------------------
  Stream<Post> streamSinglePost(String postId) {
    return _db.collection("posts").doc(postId).snapshots().map(
          (doc) => Post.fromDoc(doc),
        );
  }

  // ---------------------------------------------------------------------------
  // 🔥 STREAM : feed de tous les posts
  // ---------------------------------------------------------------------------
  Stream<List<Post>> streamFeed() {
    return _db
        .collection("posts")
        .orderBy("date", descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => Post.fromDoc(doc)).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // 🔥 CREATE : Post classique
  // ---------------------------------------------------------------------------
  Future<void> createPost(Post post) async {
    await _db.collection("posts").doc(post.id).set(post.toMap());
  }

  // ---------------------------------------------------------------------------
  // ❤️ LIKE / UNLIKE — VERSION COMPATIBLE FIRESTORE RULES
  // ---------------------------------------------------------------------------
  Future<void> toggleLike(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final postRef = _db.collection("posts").doc(postId);
    final likeRef = postRef.collection("likes").doc(uid);

    await _db.runTransaction((trx) async {
      final likeSnap = await trx.get(likeRef);

      if (likeSnap.exists) {
        // UNLIKE
        trx.delete(likeRef);
        trx.update(postRef, {"likes": FieldValue.increment(-1)});
      } else {
        // LIKE
        trx.set(likeRef, {
          "userId": uid,
          "createdAt": FieldValue.serverTimestamp(),
        });
        trx.update(postRef, {"likes": FieldValue.increment(1)});
      }
    });
  }

  // Vérifier si l’utilisateur a liké
  Future<bool> hasLiked(String postId, String uid) async {
    final likeSnap = await _db
        .collection("posts")
        .doc(postId)
        .collection("likes")
        .doc(uid)
        .get();
    return likeSnap.exists;
  }

  // ---------------------------------------------------------------------------
  // 💬 UPDATE : compteur de commentaires
  // ---------------------------------------------------------------------------
  Future<void> updateCommentsCount(String postId, int count) async {
    await _db.collection("posts").doc(postId).update({
      "commentsCount": count,
    });
  }

  // ---------------------------------------------------------------------------
  // 🔥 PARTIE SONDAGES
  // ---------------------------------------------------------------------------

  Future<void> createPoll(Post post) async {
    await _db.collection("posts").doc(post.id).set(post.toMap());
  }

  Future<void> votePoll({
    required String postId,
    required int optionIndex,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = _db.collection("posts").doc(postId);

    await _db.runTransaction((trx) async {
      final snap = await trx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List<String> voted =
          List<String>.from(data["voted"] ?? []);
      final List options = List.from(data["options"] ?? []);

      if (voted.contains(uid)) return;

      options[optionIndex]["votes"]++;

      voted.add(uid);

      trx.update(ref, {
        "options": options,
        "voted": voted,
      });
    });
  }

  // ---------------------------------------------------------------------------
  // 🔥 UPLOAD D’IMAGES (Web + Mobile)
  // ---------------------------------------------------------------------------
  Future<String> uploadImage(XFile file) async {
    final ref = FirebaseStorage.instance.ref(
      "posts/${DateTime.now().millisecondsSinceEpoch}_${file.name}",
    );

    if (kIsWeb) {
      await ref.putData(await file.readAsBytes());
    } else {
      await ref.putFile(File(file.path));
    }

    return await ref.getDownloadURL();
  }
}
