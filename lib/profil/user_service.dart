import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yolo/accueil/post/suggestions/new_users_card.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference users = FirebaseFirestore.instance.collection(
    "users",
  );

  /// ID de l'utilisateur connecté
  String get uid => _auth.currentUser!.uid;

  // --------------------------------------------------------------
  // 🔥 Création automatique du document user si inexistant
  // --------------------------------------------------------------
  Future<void> ensureUserDocument() async {
    final doc = await users.doc(uid).get();
    if (!doc.exists) {
      await users.doc(uid).set({
        "uid": uid,
        "username": "Utilisateur",
        "photoUrl": null,
        "bio": "",
        "createdAt": FieldValue.serverTimestamp(),

        // 🆕 Ajout automatique du genre si nouvel utilisateur
        "gender": "nspp",
      });
    }
  }

  // --------------------------------------------------------------
  // 🔥 Récupérer les infos user
  // --------------------------------------------------------------
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final snap = await users.doc(userId).get();
    return snap.data() as Map<String, dynamic>?;
  }

  // --------------------------------------------------------------
  // 🔥 STREAM infos user
  // --------------------------------------------------------------
  Stream<Map<String, dynamic>?> watchUser(String userId) {
    return users
        .doc(userId)
        .snapshots()
        .map((d) => d.data() as Map<String, dynamic>?);
  }

  // --------------------------------------------------------------
  // 🔥 Mettre à jour profil
  // --------------------------------------------------------------
  Future<void> updateUser(Map<String, dynamic> data) async {
    await users.doc(uid).update(data);
  }

  Future<void> updatePhoto(String url) async {
    await users.doc(uid).update({"photoUrl": url});
  }

  Future<void> updateUsername(String username) async {
    await users.doc(uid).update({"username": username});
  }

  Future<void> updateBio(String bio) async {
    await users.doc(uid).update({"bio": bio});
  }

  // --------------------------------------------------------------
  // 🆕 🔥 Sauvegarde du genre sélectionné
  // --------------------------------------------------------------
  Future<void> saveUserGender(String gender) async {
    await users.doc(uid).update({"gender": gender});
  }

  // --------------------------------------------------------------
  // 🆕 🔥 Récupérer le genre (utile pour filtres)
  // --------------------------------------------------------------
  Future<String?> getGender(String userId) async {
    final snap = await users.doc(userId).get();
    final data = snap.data() as Map<String, dynamic>?;
    return data?["gender"];
  }

  // =====================================================================
  // 🚀 MÉTHODES MANQUANTES POUR LE SUGGESTION ENGINE
  // =====================================================================

  /// 1️⃣ 🔥 Récupère le username d’un utilisateur
  Future<String> getUserName(String userId) async {
    try {
      final snap = await users.doc(userId).get();
      if (!snap.exists) return "Utilisateur";

      final data = snap.data() as Map<String, dynamic>?;

      return data?["username"] ??
          data?["name"] ??
          data?["pseudo"] ??
          "Utilisateur";
    } catch (_) {
      return "Utilisateur";
    }
  }

  /// 2️⃣ 🔥 Récupère la liste des amis d’un user
  Future<List<String>> getUserFriends(String userId) async {
    try {
      final snap = await users.doc(userId).collection("friends").get();

      return snap.docs.map((d) => d.id).toList();
    } catch (_) {
      return [];
    }
  }

  /// 3️⃣ 🔥 Nouveaux utilisateurs (carte suggestion)
  Future<List<NewUserLite>> getNewUsersLite({int limit = 10}) async {
    try {
      final snap = await users
          .orderBy("createdAt", descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>?;

        return NewUserLite(
          id: d.id,
          name: data?["username"] ?? data?["name"] ?? "Nouvel utilisateur",
          photoUrl: data?["photoUrl"],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
