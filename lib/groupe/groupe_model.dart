import 'package:cloud_firestore/cloud_firestore.dart';

class GroupeModel {
  final String id;
  final String nom;
  final String description;
  final String photoUrl;
  final String createurId;

  final List<String> admins;
  final List<String> membres;
  final List<String> bannis;
  final List<String> interets;

  /// couleur dans Firestore = string (peut être : int / "int" / "#xxxxxx" / "0xffxxxxxx")
  final String couleur;

  final String lastMessage;
  final DateTime? lastTime;

  /// 🔥 qui n’a PAS lu le dernier message
  final List<String> unreadBy;

  /// 🔥 CHAMP QUI MANQUAIT
  final bool isPublic;

  GroupeModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.photoUrl,
    required this.createurId,
    required this.admins,
    required this.membres,
    required this.bannis,
    required this.couleur,
    required this.lastMessage,
    required this.lastTime,
    required this.interets,
    required this.unreadBy,
    required this.isPublic,
  });

  // ---------------------------------------------------------
  // 🔥 Firestore → Model
  // ---------------------------------------------------------
  factory GroupeModel.fromFirestore(DocumentSnapshot doc) {
    final raw = (doc.data() as Map<String, dynamic>?) ?? {};

    return GroupeModel(
      id: doc.id,
      nom: raw["nom"]?.toString() ?? "",
      description: raw["description"]?.toString() ?? "",
      photoUrl: (raw["photoUrl"] ?? "").toString().replaceAll('"', '').trim(),
      createurId: raw["createurId"] ?? "",

      admins: List<String>.from(raw["admins"] ?? []),
      membres: List<String>.from(raw["membres"] ?? []),
      bannis: List<String>.from(raw["bannis"] ?? []),

      interets: List<String>.from(raw["interets"] ?? []),

      couleur: raw["couleur"]?.toString().trim() ?? "0xffA855F7",

      lastMessage: raw["lastMessage"]?.toString() ?? "",

      lastTime: raw["lastTime"] is Timestamp
          ? (raw["lastTime"] as Timestamp).toDate()
          : null,

      unreadBy: List<String>.from(raw["unreadBy"] ?? []),

      /// 🔥 si Firestore n'a pas isPublic, on met true par défaut
      isPublic: raw["isPublic"] is bool ? raw["isPublic"] : true,
    );
  }

  // ---------------------------------------------------------
  // 🔥 Model → Firestore
  // ---------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      "nom": nom,
      "description": description,
      "photoUrl": photoUrl,
      "createurId": createurId,

      "admins": admins,
      "membres": membres,
      "bannis": bannis,

      "couleur": couleur,
      "interets": interets,

      "lastMessage": lastMessage,
      "lastTime": lastTime,
      "unreadBy": unreadBy,

      "isPublic": isPublic,
    };
  }

  // ---------------------------------------------------------
  // 🔥 Convertit couleur string → int utilisable dans Color()
  // ---------------------------------------------------------
  int toColorInt() {
    final c = couleur.trim();

    if (c.startsWith("#")) {
      return int.parse(c.replaceFirst("#", "0xff"));
    }

    if (c.startsWith("0x")) {
      return int.parse(c);
    }

    return int.tryParse(c) ?? 0xffA855F7;
  }
}
