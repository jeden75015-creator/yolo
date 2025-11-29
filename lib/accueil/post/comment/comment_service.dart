import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comment_model.dart';
import 'package:yolo/notifications/notification_service.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========================================================================
  // 🔥 AJOUTER UN COMMENTAIRE + NOTIFICATION
  // ========================================================================
  Future<void> addComment({
    required String postId,
    required String texte,
    String? parentId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🔹 Récupération des infos user
    final userDoc = await _db.collection("users").doc(uid).get();
    final data = userDoc.data() ?? {};

    final first = data["firstName"] ?? "";
    final last = data["lastName"] ?? "";
    final userPhoto = data["userPhoto"] ?? data["photoUrl"] ?? "";

    final displayName =
        (first + " " + last).trim().isEmpty ? "Utilisateur" : "$first $last";

    // 🔹 Récupération de l’AUTEUR DU POST
    final postDoc = await _db.collection("posts").doc(postId).get();
    final postData = postDoc.data() ?? {};
    final postOwnerId = postData["userId"] ?? "";

    final col = _db
        .collection("posts")
        .doc(postId)
        .collection("comments");

    final id = col.doc().id;

    final comment = CommentModel(
      id: id,
      userId: uid,
      userName: displayName,
      userPhoto: userPhoto,
      postId: postId,
      texte: texte,
      date: DateTime.now(),
      parentId: parentId,
    );

    // 🔥 Enregistrer commentaire
    await col.doc(id).set(comment.toMap());

    // 🔥 Incrément compteur
    await _db.collection("posts").doc(postId).update({
      "commentsCount": FieldValue.increment(1),
    });

    // ======================================================================
    // 🔥 ENVOYER NOTIFICATION COMMENTAIRE
    // ======================================================================
    if (postOwnerId.isNotEmpty && postOwnerId != uid) {
      await NotificationService.instance.sendCommentPostNotification(
        postOwnerId: postOwnerId,
        postId: postId,
        commentText: texte,
      );
    }
  }

  // ========================================================================
  // 🔥 STREAM DE COMMENTAIRES
  // ========================================================================
  Stream<List<CommentModel>> getComments(String postId) {
    return _db
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .orderBy("date", descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommentModel.fromDoc(d))
            .toList());
  }

  // ========================================================================
  // 🔥 SUPPRIMER UN COMMENTAIRE
  // ========================================================================
  Future<void> deleteComment(String postId, String commentId) async {
    await _db
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .doc(commentId)
        .delete();

    await _db.collection("posts").doc(postId).update({
      "commentsCount": FieldValue.increment(-1),
    });
  }

  // ========================================================================
  // 🔥 RÉACTIONS COMMENTAIRES
  // ========================================================================
  Stream<CommentReactions> getReactions(
    String postId,
    String commentId,
  ) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final col = _db
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .doc(commentId)
        .collection("reactions");

    return col.snapshots().map((snap) {
      final Map<String, int> counts = {
        "like": 0,
        "love": 0,
        "haha": 0,
        "wow": 0,
      };

      String? myType;

      for (final d in snap.docs) {
        final data = d.data();
        final type = data["type"] ?? "like";

        counts[type] = (counts[type] ?? 0) + 1;

        if (d.id == uid) myType = type;
      }

      return CommentReactions(
        counts: counts,
        myType: myType,
      );
    });
  }

  // ========================================================================
  // 🔥 SET / CHANGE REACTION
  // ========================================================================
  Future<void> setReaction({
    required String postId,
    required String commentId,
    required String type,
    required String? currentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = _db
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .doc(commentId)
        .collection("reactions")
        .doc(uid);

    if (currentType == type) {
      await ref.delete();
    } else {
      await ref.set({
        "type": type,
        "date": FieldValue.serverTimestamp(),
      });
    }
  }
}

// ============================================================================
// MODEL RÉACTIONS COMMENTAIRES
// ============================================================================
class CommentReactions {
  final Map<String, int> counts;
  final String? myType;

  CommentReactions({
    required this.counts,
    required this.myType,
  });
}
