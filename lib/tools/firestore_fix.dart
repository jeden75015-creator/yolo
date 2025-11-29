// ============================================================================
// 🔥 FirestoreFix — Corrige les anciens posts mal formatés
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreFix {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ==========================================================================
  /// 🔥 Lancer toutes les corrections (posts + commentaires)
  /// ==========================================================================
  static Future<void> run() async {
    print("🚀 FirestoreFix : démarrage...");

    await _fixPosts();
    await _fixComments();

    print("✅ FirestoreFix : terminé !");
  }

  /// ==========================================================================
  /// 🔧 Correction : Posts
  /// ==========================================================================
  static Future<void> _fixPosts() async {
    print("🔧 Correction des posts...");

    final snap = await _db.collection("posts").get();

    for (final doc in snap.docs) {
      final data = doc.data();

      final updates = <String, dynamic>{};

      // ---- Supprimer anciens champs
      if (data.containsKey("avatarUrl")) updates["avatarUrl"] = FieldValue.delete();
      if (data.containsKey("name")) updates["name"] = FieldValue.delete();

      // ---- Forcer champs manquants
      if (!data.containsKey("commentsCount")) updates["commentsCount"] = 0;
      if (!data.containsKey("likes")) updates["likes"] = 0;

      // ---- Dates manquantes
      if (data["date"] == null) {
        updates["date"] = DateTime.now();
      }

      // ---- PhotoUrls = liste obligatoire
      if (data["photoUrls"] == null || data["photoUrls"] is! List) {
        updates["photoUrls"] = [];
      }

      // ---- Sondage
      if (data["isPoll"] == true) {
        if (data["options"] == null || data["options"] is! List) {
          updates["options"] = [];
        }
        if (data["voted"] == null || data["voted"] is! List) {
          updates["voted"] = [];
        }
      }

      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
        print("✔️ Post corrigé : ${doc.id}");
      }
    }

    print("✅ Posts corrigés");
  }

  /// ==========================================================================
  /// 🔧 Correction : Commentaires
  /// ==========================================================================
  static Future<void> _fixComments() async {
    print("🔧 Correction des commentaires...");

    final posts = await _db.collection("posts").get();

    for (final post in posts.docs) {
      final comments = await post.reference.collection("comments").get();

      for (final c in comments.docs) {
        final data = c.data();

        final updates = <String, dynamic>{};

        if (!data.containsKey("userPhoto")) updates["userPhoto"] = null;
        if (!data.containsKey("date")) updates["date"] = DateTime.now();

        if (!data.containsKey("likes")) updates["likes"] = 0;
        if (!data.containsKey("repliesCount")) updates["repliesCount"] = 0;

        if (updates.isNotEmpty) {
          await c.reference.update(updates);
          print("✔️ Commentaire corrigé : ${c.id}");
        }
      }
    }

    print("✅ Commentaires corrigés");
  }
}
