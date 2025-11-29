import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart'; // 🔥 AJOUT ICI

class Activite {
  final String id;
  final String titre;
  final String description;
  final String photoUrl;
  final DateTime date;
  final bool estGratuite;
  final String adresse;
  final String region;
  final int maxParticipants;
  final String createurId;
  final String categorie;
  final bool modeDiscret;

  final List<String> participants;
  final List<String> participantsAttente;
  final List<String> organisateurs;

  final String? duree;

  // 📍 NON NULLABLE — OBLIGATOIRE POUR FIRESTORE
  final double latitude;
  final double longitude;

  final bool notified3hBefore;

  Activite({
    required this.id,
    required this.titre,
    required this.description,
    required this.photoUrl,
    required this.date,
    required this.estGratuite,
    required this.adresse,
    required this.region,
    required this.maxParticipants,
    required this.createurId,
    required this.categorie,
    required this.modeDiscret,
    required this.participants,
    required this.participantsAttente,
    required this.organisateurs,
    this.duree,
    required this.latitude,
    required this.longitude,
    required this.notified3hBefore,
  });

  factory Activite.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    return Activite(
      id: doc.id,
      titre: d["titre"] ?? "",
      description: d["description"] ?? "",

      // 🔥🔥🔥 LA LIGNE QUI RÈGLE TOUT 🔥🔥🔥
      photoUrl: StorageHelper.convert(d["photoUrl"] ?? ""),

      date: (d["date"] is Timestamp)
          ? (d["date"] as Timestamp).toDate()
          : DateTime.now(),
      estGratuite: d["estGratuite"] ?? true,
      adresse: d["adresse"] ?? "",
      region: d["region"] ?? "",
      maxParticipants: d["maxParticipants"] ?? 10,
      createurId: d["createurId"] ?? "",
      categorie: d["categorie"] ?? "",
      modeDiscret: d["modeDiscret"] ?? false,
      participants: List<String>.from(d["participants"] ?? []),
      participantsAttente: List<String>.from(d["participantsAttente"] ?? []),
      organisateurs: List<String>.from(d["organisateurs"] ?? []),
      duree: d["duree"],

      latitude: (d["latitude"] as num?)?.toDouble() ?? 0.0,
      longitude: (d["longitude"] as num?)?.toDouble() ?? 0.0,

      notified3hBefore: d["notified3hBefore"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "titre": titre,
      "description": description,
      "photoUrl": photoUrl,
      "date": Timestamp.fromDate(date),
      "estGratuite": estGratuite,
      "adresse": adresse,
      "region": region,
      "maxParticipants": maxParticipants,
      "createurId": createurId,
      "categorie": categorie,
      "modeDiscret": modeDiscret,
      "participants": participants,
      "participantsAttente": participantsAttente,
      "organisateurs": organisateurs,
      "duree": duree,
      "latitude": latitude,
      "longitude": longitude,
      "notified3hBefore": notified3hBefore,
    };
  }
}
