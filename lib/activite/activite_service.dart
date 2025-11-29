import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'activite_model.dart';
import '../widgets/helpers/storage_helper.dart'; // 🔥 AJOUT OBLIGATOIRE

class ActiviteService {
  final _col = FirebaseFirestore.instance.collection("activites");
  final _user = FirebaseAuth.instance.currentUser!;

  // ------------------------------------------------------------------
  // STREAMS / GETTERS
  // ------------------------------------------------------------------

  Stream<List<Activite>> streamActivites() {
    return _col.orderBy("date", descending: false).snapshots().map((snap) {
      return snap.docs.map((d) {
        return Activite.fromFirestore(d);
      }).toList();
    });
  }

  Future<List<Activite>> getActivites() async {
    final snap = await _col.orderBy("date", descending: false).get();
    return snap.docs.map((d) => Activite.fromFirestore(d)).toList();
  }

  Future<Activite?> getActivite(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Activite.fromFirestore(doc);
  }

  // ------------------------------------------------------------------
  // CRÉATION
  // ------------------------------------------------------------------

  Future<void> creerActivite(Activite act) async {
    await _col.doc(act.id).set({
      "id": act.id,
      "titre": act.titre,
      "description": act.description,

      // 🔥 Toujours converti
      "photoUrl": StorageHelper.convert(act.photoUrl),

      "date": Timestamp.fromDate(act.date),
      "estGratuite": act.estGratuite,
      "adresse": act.adresse,
      "region": act.region,
      "maxParticipants": act.maxParticipants,
      "createurId": act.createurId,
      "categorie": act.categorie,
      "modeDiscret": act.modeDiscret,
      "participants": act.participants,
      "participantsAttente": act.participantsAttente,
      "organisateurs": act.organisateurs,
      "duree": act.duree,

      "latitude": act.latitude,
      "longitude": act.longitude,

      "notified3hBefore": act.notified3hBefore,

      "lastMessage": "",
      "lastTime": FieldValue.serverTimestamp(),
      "unreadBy": [],
    });
  }

  // ------------------------------------------------------------------
  // MODIFICATION
  // ------------------------------------------------------------------

  Future<void> modifierActivite({
    required String activiteId,
    String? titre,
    String? description,
    String? adresse,
    String? region,
    String? photoUrl,
    DateTime? date,
    String? categorie,
    int? maxParticipants,
    String? duree,
  }) async {
    final Map<String, dynamic> data = {};

    if (titre != null) data["titre"] = titre;
    if (description != null) data["description"] = description;
    if (adresse != null) data["adresse"] = adresse;
    if (region != null) data["region"] = region;

    // 🔥 Conversion auto si nouvelle image
    if (photoUrl != null) data["photoUrl"] = StorageHelper.convert(photoUrl);

    if (date != null) data["date"] = Timestamp.fromDate(date);
    if (categorie != null) data["categorie"] = categorie;
    if (maxParticipants != null) data["maxParticipants"] = maxParticipants;
    if (duree != null) data["duree"] = duree;

    await _col.doc(activiteId).update(data);
  }

  // ------------------------------------------------------------------
  // 🔥 ENVOI MESSAGE → mise à jour lastMessage + unreadBy
  // ------------------------------------------------------------------

  Future<void> updateLastMessage(String activiteId, String message) async {
    final doc = await _col.doc(activiteId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final membres = List<String>.from(data["participants"] ?? []);
    final sender = _user.uid;

    final unreadTargets = membres.where((id) => id != sender).toList();

    await _col.doc(activiteId).update({
      "lastMessage": message,
      "lastTime": FieldValue.serverTimestamp(),
      "unreadBy": unreadTargets,
    });
  }

  // ------------------------------------------------------------------
  // MARQUER COMME LU
  // ------------------------------------------------------------------

  Future<void> markAsRead(String activiteId) async {
    await _col.doc(activiteId).update({
      "unreadBy": FieldValue.arrayRemove([_user.uid]),
    });
  }

  // ------------------------------------------------------------------
  // PARTICIPER
  // ------------------------------------------------------------------

  Future<void> rejoindreActivite(String id, String uid) async {
    final docRef = _col.doc(id);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<String> participants = List<String>.from(
      data["participants"] ?? [],
    );
    final List<String> attente = List<String>.from(
      data["participantsAttente"] ?? [],
    );
    final int max = data["maxParticipants"] ?? 0;

    if (participants.contains(uid) || attente.contains(uid)) return;

    if (participants.length < max) {
      participants.add(uid);
    } else {
      attente.add(uid);
    }

    await docRef.update({
      "participants": participants,
      "participantsAttente": attente,
      "unreadBy": FieldValue.arrayRemove([uid]),
    });
  }

  // ------------------------------------------------------------------
  // QUITTER
  // ------------------------------------------------------------------

  Future<void> quitterActivite(String id, String uid) async {
    final docRef = _col.doc(id);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<String> participants = List<String>.from(
      data["participants"] ?? [],
    );
    final List<String> attente = List<String>.from(
      data["participantsAttente"] ?? [],
    );

    final wasParticipant = participants.remove(uid);
    attente.remove(uid);

    await docRef.update({
      "participants": participants,
      "participantsAttente": attente,
      "unreadBy": FieldValue.arrayRemove([uid]),
    });

    // Upgrade depuis liste d’attente
    if (wasParticipant && attente.isNotEmpty) {
      final next = attente.first;

      attente.removeAt(0);
      participants.add(next);

      await docRef.update({
        "participants": participants,
        "participantsAttente": attente,
      });

      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": next,
        "type": "promotion_liste_attente",
        "message":
            "🎉 Une place s’est libérée : vous êtes désormais participant !",
        "activiteId": id,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  // ------------------------------------------------------------------
  // NOTIFICATION AUTOMATIQUE 3H AVANT
  // ------------------------------------------------------------------

  Future<void> checkNotifications3hBefore() async {
    final now = DateTime.now();

    final sn = await _col.get();
    for (final doc in sn.docs) {
      final act = Activite.fromFirestore(doc);

      if (act.notified3hBefore) continue;

      final int diff = act.date.difference(now).inMinutes;

      if (diff < 190 && diff > 170) {
        await _col.doc(act.id).collection("chat").add({
          "userId": "system",
          "message":
              "⏰ Votre activité commence dans 3 heures.\n"
              "📍 ${act.adresse}\n"
              "🗺 ${act.region}\n"
              "🕒 Début : ${DateFormat("HH:mm").format(act.date)}",
          "createdAt": FieldValue.serverTimestamp(),
        });

        await _col.doc(act.id).update({"notified3hBefore": true});
      }
    }
  }
}
