import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'groupe_model.dart';
import '../widgets/helpers/storage_helper.dart';

class GroupeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  // ============================================================
  // 🔥 STREAM DES GROUPES (ceux où je suis membre)
  // ============================================================
  Stream<List<GroupeModel>> streamGroupes() {
    final uid = _auth.currentUser!.uid;

    return _fire
        .collection("groupes")
        .where("membres", arrayContains: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            final data = d.data();

            // 🔥 Sécurisation de la photo GS->HTTPS
            final fixedPhoto = data["photoUrl"] != null
                ? StorageHelper.convert(data["photoUrl"])
                : StorageHelper.defaultGroup();

            return GroupeModel(
              id: d.id,
              nom: data["nom"] ?? "",
              description: data["description"] ?? "",
              photoUrl: fixedPhoto,
              interets: List<String>.from(data["interets"] ?? []),
              createurId: data["createurId"] ?? "",

              membres: List<String>.from(data["membres"] ?? []),
              admins: List<String>.from(data["admins"] ?? []),
              bannis: List<String>.from(data["bannis"] ?? []),

              isPublic: data["isPublic"] ?? true,

              couleur: data["couleur"]?.toString() ?? "0xff888888",

              lastMessage: data["lastMessage"] ?? "",
              lastTime: (data["lastTime"] as Timestamp?)?.toDate(),

              unreadBy: List<String>.from(data["unreadBy"] ?? []),
            );
          }).toList();

          // 🔥 tri par dernier message (descendant)
          list.sort((a, b) {
            final ta = a.lastTime ?? DateTime(2000);
            final tb = b.lastTime ?? DateTime(2000);
            return tb.compareTo(ta);
          });

          return list;
        });
  }

  // ============================================================
  // 🔥 CRÉER UN GROUPE (version stable, sans "prive")
  // ============================================================
  Future<String> creerGroupe({
    required String nom,
    required String description,
    required dynamic couleur, // int | string
    required bool isPublic,
    required String photoUrl,
    required List<String> interets,
  }) async {
    final doc = _db.collection("groupes").doc();

    await doc.set({
      "nom": nom,
      "description": description,
      "photoUrl": photoUrl,
      "couleur": couleur.toString(),
      "isPublic": isPublic,

      "createurId": _auth.currentUser!.uid,
      "admins": [_auth.currentUser!.uid],
      "membres": [_auth.currentUser!.uid],
      "bannis": [],
      "interets": interets,

      "lastMessage": "",
      "lastTime": FieldValue.serverTimestamp(),
      "unreadBy": [],
    });

    return doc.id;
  }

  // ============================================================
  Future<void> updateInterets(String id, List<String> interets) async {
    await _db.collection("groupes").doc(id).update({"interets": interets});
  }

  // ============================================================
  Stream<GroupeModel> listenGroup(String groupId) {
    return _db
        .collection("groupes")
        .doc(groupId)
        .snapshots()
        .map((snap) => GroupeModel.fromFirestore(snap));
  }

  // ============================================================
  Future<List<GroupeModel>> getMyGroups() async {
    final res = await _db
        .collection("groupes")
        .where("membres", arrayContains: _auth.currentUser!.uid)
        .get();

    return res.docs.map((d) => GroupeModel.fromFirestore(d)).toList();
  }

  // ============================================================
  Future<List<GroupeModel>> getPublicGroups() async {
    final res = await _db
        .collection("groupes")
        .where("isPublic", isEqualTo: true)
        .get();

    return res.docs.map((d) => GroupeModel.fromFirestore(d)).toList();
  }

  // ============================================================
  Future<void> updateLastMessage(String groupId, String message) async {
    final uid = _auth.currentUser!.uid;

    final snap = await _db.collection("groupes").doc(groupId).get();
    if (!snap.exists) return;

    final membres = List<String>.from(snap["membres"] ?? []);

    // 🔥 tous sauf l'expéditeur
    final unread = membres.where((m) => m != uid).toList();

    await _db.collection("groupes").doc(groupId).update({
      "lastMessage": message,
      "lastTime": FieldValue.serverTimestamp(),
      "unreadBy": unread,
    });
  }

  // ============================================================
  Future<void> markGroupAsRead(String groupId) async {
    await _db.collection("groupes").doc(groupId).update({
      "unreadBy": FieldValue.arrayRemove([_auth.currentUser!.uid]),
    });
  }

  // ============================================================
  Future<void> rejoindreGroupe(String groupId) async {
    await _db.collection("groupes").doc(groupId).update({
      "membres": FieldValue.arrayUnion([_auth.currentUser!.uid]),
      "bannis": FieldValue.arrayRemove([_auth.currentUser!.uid]),
      "unreadBy": FieldValue.arrayRemove([_auth.currentUser!.uid]),
    });
  }

  // ============================================================
  Future<void> quitterGroupe(String groupId) async {
    await _db.collection("groupes").doc(groupId).update({
      "membres": FieldValue.arrayRemove([_auth.currentUser!.uid]),
      "admins": FieldValue.arrayRemove([_auth.currentUser!.uid]),
      "unreadBy": FieldValue.arrayRemove([_auth.currentUser!.uid]),
    });
  }

  // ============================================================
  Future<void> bannirMembre(String groupId, String uid) async {
    await _db.collection("groupes").doc(groupId).update({
      "membres": FieldValue.arrayRemove([uid]),
      "admins": FieldValue.arrayRemove([uid]),
      "bannis": FieldValue.arrayUnion([uid]),
      "unreadBy": FieldValue.arrayRemove([uid]),
    });
  }

  // ============================================================
  Future<void> debannirMembre(String groupId, String uid) async {
    await _db.collection("groupes").doc(groupId).update({
      "bannis": FieldValue.arrayRemove([uid]),
    });
  }

  // ============================================================
  Future<void> ajouterAdmin(String groupId, String uid) async {
    await _db.collection("groupes").doc(groupId).update({
      "admins": FieldValue.arrayUnion([uid]),
    });
  }

  // ============================================================
  Future<void> retirerAdmin(String groupId, String uid) async {
    await _db.collection("groupes").doc(groupId).update({
      "admins": FieldValue.arrayRemove([uid]),
    });
  }

  // ============================================================
  Future<void> retirerMembre(String groupId, String uid) async {
    await _db.collection("groupes").doc(groupId).update({
      "membres": FieldValue.arrayRemove([uid]),
      "admins": FieldValue.arrayRemove([uid]),
      "unreadBy": FieldValue.arrayRemove([uid]),
    });
  }

  // ============================================================
  // 🔥 SIGNALER MEMBRE (auto-ban si 5 signalements)
  // ============================================================
  Future<void> signalerMembre(String groupId, String cibleId) async {
    final uid = _auth.currentUser!.uid;

    final ref = _db
        .collection("groupes")
        .doc(groupId)
        .collection("signals")
        .doc(cibleId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      List signalers = [];
      if (snap.exists) {
        signalers = List.from(snap.data()?["signalers"] ?? []);
      }

      // 🔒 déjà signalé
      if (signalers.contains(uid)) return;

      signalers.add(uid);

      // 🔥 ajout du signalement
      tx.set(ref, {"signalers": signalers}, SetOptions(merge: true));

      // 🔥 si >= 5 → autoban (sauf admin)
      if (signalers.length >= 5) {
        final gref = _db.collection("groupes").doc(groupId);
        final gSnap = await tx.get(gref);
        final data = gSnap.data()!;

        final admins = List<String>.from(data["admins"] ?? []);

        if (!admins.contains(cibleId)) {
          tx.update(gref, {
            "bannis": FieldValue.arrayUnion([cibleId]),
            "membres": FieldValue.arrayRemove([cibleId]),
            "unreadBy": FieldValue.arrayRemove([cibleId]),
          });
        }
      }
    });
  }
}
