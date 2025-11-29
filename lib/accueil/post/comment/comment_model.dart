import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;   // 🔥 avatar auteur du commentaire
  final String postId;
  final String texte;
  final DateTime date;
  final String? parentId;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.postId,
    required this.texte,
    required this.date,
    this.parentId,
  });

  // -------------------------------------
  // Firestore → Model
  // -------------------------------------
  factory CommentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CommentModel(
      id: data["id"] ?? doc.id,
      userId: data["userId"] ?? "",
      userName: data["userName"] ?? "Utilisateur",
      userPhoto: data["userPhoto"] ?? data["photoUrl"] ?? "",
      postId: data["postId"] ?? "",
      texte: data["texte"] ?? "",
      date: (data["date"] as Timestamp).toDate(),
      parentId: data["parentId"],
    );
  }

  // -------------------------------------
  // Model → Map
  // -------------------------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "userName": userName,
      "userPhoto": userPhoto,   // 👈 un seul nom
      "postId": postId,
      "texte": texte,
      "date": date,
      "parentId": parentId,
    };
  }
}
