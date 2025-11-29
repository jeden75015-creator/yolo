import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ---------------------------------------------------------------------------
/// POLL OPTION
/// ---------------------------------------------------------------------------
class PollOption {
  final String text;
  final int votes;

  PollOption({
    required this.text,
    required this.votes,
  });

  Map<String, dynamic> toMap() => {
        "text": text,
        "votes": votes,
      };

  factory PollOption.fromMap(Map<String, dynamic> d) {
    return PollOption(
      text: d["text"] ?? "",
      votes: d["votes"] ?? 0,
    );
  }

  PollOption copyWith({String? text, int? votes}) {
    return PollOption(
      text: text ?? this.text,
      votes: votes ?? this.votes,
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST MODEL — compatible sous-collection /likes/{uid}
/// ---------------------------------------------------------------------------
class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;

  final String? titre;
  final String? texte;
  final List<String> photoUrls;

  final DateTime date;

  final int likes;
  final bool likedByMe;

  final int commentsCount;

  // Poll
  final bool isPoll;
  final String? question;
  final List<PollOption> options;
  final List<String> voted;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.titre,
    required this.texte,
    required this.photoUrls,
    required this.date,
    required this.likes,
    required this.likedByMe,
    required this.commentsCount,
    required this.isPoll,
    required this.question,
    required this.options,
    required this.voted,
  });

  /// ---------------------------------------------------------------------------
  /// FROM FIRESTORE (sans likedByMe → mise à jour après via méthode async)
  /// ---------------------------------------------------------------------------
  factory Post.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    return Post(
      id: d["id"] ?? doc.id,
      userId: d["userId"] ?? "",
      userName: d["userName"] ?? "Utilisateur",
      userPhoto: d["userPhoto"] ?? d["photoUrl"],

      titre: d["titre"],
      texte: d["texte"],
      photoUrls: List<String>.from(d["photoUrls"] ?? []),

      date: (d["date"] is Timestamp)
          ? (d["date"] as Timestamp).toDate()
          : DateTime(2000),

      likes: d["likes"] ?? 0,
      likedByMe: false,   // ⚠️ sera mis à jour ensuite
      commentsCount: d["commentsCount"] ?? 0,

      isPoll: d["isPoll"] ?? false,
      question: d["question"],
      options: (d["options"] as List<dynamic>? ?? [])
          .map((o) => PollOption.fromMap(o))
          .toList(),
      voted: List<String>.from(d["voted"] ?? []),
    );
  }

  /// ---------------------------------------------------------------------------
  /// MAP POUR FIRESTORE
  /// ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "userName": userName,
      "userPhoto": userPhoto,

      "titre": titre,
      "texte": texte,
      "photoUrls": photoUrls,

      "date": date,
      "likes": likes,
      "commentsCount": commentsCount,

      "isPoll": isPoll,
      "question": question,
      "options": options.map((o) => o.toMap()).toList(),
      "voted": voted,
    };
  }

  /// ---------------------------------------------------------------------------
  /// COPYWITH
  /// ---------------------------------------------------------------------------
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    String? titre,
    String? texte,
    List<String>? photoUrls,
    DateTime? date,
    int? likes,
    bool? likedByMe,
    int? commentsCount,
    bool? isPoll,
    String? question,
    List<PollOption>? options,
    List<String>? voted,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,

      titre: titre ?? this.titre,
      texte: texte ?? this.texte,
      photoUrls: photoUrls ?? this.photoUrls,

      date: date ?? this.date,

      likes: likes ?? this.likes,
      likedByMe: likedByMe ?? this.likedByMe,
      commentsCount: commentsCount ?? this.commentsCount,

      isPoll: isPoll ?? this.isPoll,
      question: question ?? this.question,
      options: options ?? this.options,
      voted: voted ?? this.voted,
    );
  }

  /// ---------------------------------------------------------------------------
  /// Renvoie l’index du vote de l’utilisateur
  /// ---------------------------------------------------------------------------
  int? get myVote {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    if (!voted.contains(uid)) return null;
    return null; // (corrigé dans PollCard)
  }
}
