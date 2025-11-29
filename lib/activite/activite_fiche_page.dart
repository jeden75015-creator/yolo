// -----------------------------------------------------------------------------
// 📄 PAGE : ActiviteFichePage (Fiche + Chat embarqué)
// -----------------------------------------------------------------------------

import 'dart:ui'; // pour ImageFilter (si besoin plus tard)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';

import 'activite_model.dart';
import 'activite_service.dart';
import 'categorie_data.dart';
import 'activite_chat_page.dart'; // pour ouvrir le chat en plein écran
import 'activite_modification_page.dart';
import '../profil/profil.dart';

class ActiviteFichePage extends StatefulWidget {
  final String activiteId;

  const ActiviteFichePage({super.key, required this.activiteId});

  @override
  State<ActiviteFichePage> createState() => _ActiviteFichePageState();
}

class _ActiviteFichePageState extends State<ActiviteFichePage> {
  final _service = ActiviteService();

  Activite? activite;
  bool loading = true;
  bool showAllParticipants = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final act = await _service.getActivite(widget.activiteId);
    if (!mounted) return;
    setState(() {
      activite = act;
      loading = false;
    });
  }

  Future<void> _toggleParticipation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || activite == null) return;

    final a = activite!;
    final inside = a.participants.contains(uid);
    final waiting = a.participantsAttente.contains(uid);

    if (inside || waiting) {
      await _service.quitterActivite(a.id, uid);
    } else {
      await _service.rejoindreActivite(a.id, uid);
    }

    await _load();
  }

  String _formatDateLigne(DateTime date) {
    // Exemple : "Lundi 05/02"
    final jour = DateFormat('EEEE dd/MM', 'fr_FR').format(date);
    return jour[0].toUpperCase() + jour.substring(1);
  }

  String _formatHeure(DateTime date) {
    return DateFormat("HH'h'mm", 'fr_FR').format(date); // 19h00
  }

  @override
  Widget build(BuildContext context) {
    if (loading || activite == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final a = activite!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final isCreator = a.createurId == uid;
    final inside = a.participants.contains(uid);
    final waiting = a.participantsAttente.contains(uid);
    final isFull = a.participants.length >= a.maxParticipants;

    final color =
        CategorieData.categories[a.categorie]?["color"] ?? Colors.deepPurple;
    final textColor =
        CategorieData.categories[a.categorie]?["textColor"] ?? Colors.white;

    final canChat = isCreator || inside;

    // Hauteur responsive pour le bloc chat
    final screenHeight = MediaQuery.of(context).size.height;
    double chatHeight = screenHeight * 0.45;
    if (chatHeight > 400) chatHeight = 400;
    if (chatHeight < 260) chatHeight = 260;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  // -----------------------------------------------------------------
                  // Bouton fermer (croix)
                  // -----------------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black26,
                          ),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ---------------------------------------------------------------------
                  // 🟪 CARTE ACTIVITÉ (fond couleur + photo)
                  // ---------------------------------------------------------------------
                  Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // IMAGE + BADGE CAT + BADGE DATE
                        SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image(
                                  image: a.photoUrl.isNotEmpty
                                      ? NetworkImage(
                                          StorageHelper.convert(a.photoUrl),
                                        )
                                      : const AssetImage(
                                              "assets/images/placeholder.jpg",
                                            )
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                                // Léger dégradé pour lisibilité des badges
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.20),
                                        Colors.black.withOpacity(0.55),
                                      ],
                                    ),
                                  ),
                                ),
                                // Badge catégorie
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      a.categorie,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                // Badge jour/date
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        "EEE d",
                                        'fr_FR',
                                      ).format(a.date).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // -----------------------------------------------------------------
                        // CONTENU TEXTE
                        // -----------------------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10),

                              // Titre (22, centré, couleur textColor)
                              Text(
                                a.titre,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Ligne centrée : 📅 date – ⏰ heure – ⏳ durée
                              Center(
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          size: 18,
                                          color: textColor.withOpacity(0.9),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateLigne(a.date),
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 18,
                                          color: textColor.withOpacity(0.9),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatHeure(a.date),
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (a.duree != null &&
                                        a.duree!.trim().isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timelapse,
                                            size: 18,
                                            color: textColor.withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            a.duree!,
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Description (alignée à gauche)
                              Text(
                                a.description,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.left,
                              ),

                              const SizedBox(height: 18),

                              // Ligne fine centrée
                              Divider(
                                color: textColor.withOpacity(0.25),
                                thickness: 0.7,
                                indent: 60,
                                endIndent: 60,
                              ),

                              const SizedBox(height: 12),

                              // Organisé par [avatar] Prénom (une seule ligne)
                              Center(
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(a.createurId)
                                      .get(),
                                  builder: (_, snap) {
                                    if (!snap.hasData || !snap.data!.exists) {
                                      return const SizedBox();
                                    }

                                    final data =
                                        snap.data!.data()
                                            as Map<String, dynamic>;
                                    final prenom =
                                        data["firstName"] ?? "Organisateur";
                                    final photo = data["photoUrl"] ?? "";

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Organisé par ",
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.8),
                                            fontSize: 15,
                                          ),
                                        ),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: photo.isNotEmpty
                                              ? NetworkImage(photo)
                                              : null,
                                          child: photo.isEmpty
                                              ? Icon(
                                                  Icons.person,
                                                  color: textColor,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          prenom,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Ligne fine centrée
                              Divider(
                                color: textColor.withOpacity(0.25),
                                thickness: 0.7,
                                indent: 60,
                                endIndent: 60,
                              ),

                              const SizedBox(height: 16),

                              // Adresse & Région (alignés à gauche)
                              _info(Icons.place, a.adresse, textColor),
                              _info(Icons.map, a.region, textColor),

                              const SizedBox(height: 16),

                              // 🗺️ Google Maps
                              SizedBox(
                                height: 220,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: kIsWeb
                                      ? Image.network(
                                          "https://maps.googleapis.com/maps/api/staticmap"
                                          "?center=${a.latitude},${a.longitude}"
                                          "&zoom=15"
                                          "&size=600x300"
                                          "&maptype=roadmap"
                                          "&markers=color:red%7C${a.latitude},${a.longitude}"
                                          "&key=AIzaSyBfm6IoyNEj8mCtnMCjOy-dsOELJt0efpk",
                                          fit: BoxFit.cover,
                                        )
                                      : GoogleMap(
                                          initialCameraPosition:
                                              CameraPosition(
                                                target: LatLng(
                                                  a.latitude,
                                                  a.longitude,
                                                ),
                                                zoom: 14,
                                              ),
                                          markers: {
                                            Marker(
                                              markerId: const MarkerId(
                                                "position",
                                              ),
                                              position: LatLng(
                                                a.latitude!,
                                                a.longitude!,
                                              ),
                                            ),
                                          },
                                          zoomControlsEnabled: false,
                                          liteModeEnabled: true,
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // PARTICIPANTS
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Participants (${a.participants.length}/${a.maxParticipants})",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                              _participantsList(a, textColor),

                              const SizedBox(height: 18),

                              // LISTE D'ATTENTE (toujours affichée, légèrement décalée)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "📌 Liste d'attente",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (a.participantsAttente.isEmpty)
                                      Text(
                                        "Personne en liste d’attente pour le moment.",
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                      )
                                    else
                                      _waitingList(a, textColor),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 26),

                              // BOUTON PRINCIPAL CENTRÉ
                              _mainActionButton(
                                activite: a,
                                isCreator: isCreator,
                                inside: inside,
                                waiting: waiting,
                                isFull: isFull,
                                color: color,
                                textColor: textColor,
                              ),

                              const SizedBox(height: 24),

                              // CHAT EMBARQUÉ (uniquement si participant ou créateur)
                              if (canChat) ...[
                                Text(
                                  "Discussion de l’activité",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: chatHeight,
                                  child: _EmbeddedActiviteChat(
                                    activiteId: a.id,
                                    categoryColor: color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGETS D'INFO
  // ---------------------------------------------------------------------------

  Widget _info(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: textColor.withOpacity(0.8), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _participantsList(Activite a, Color textColor) {
    final ids = showAllParticipants
        ? a.participants
        : a.participants.take(6).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: ids.map((uid) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(userId: uid)),
            );
          },
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .get(),
            builder: (_, snap) {
              if (!snap.hasData || !snap.data!.exists) {
                return const CircleAvatar(
                  radius: 26,
                  child: Icon(Icons.person),
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>;
              final photo = data["photoUrl"] ?? "";
              final name = data["firstName"] ?? "—";

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: photo.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 70,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _waitingList(Activite a, Color textColor) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: a.participantsAttente.map((uid) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
          builder: (_, snap) {
            if (!snap.hasData || !snap.data!.exists) {
              return const CircleAvatar(radius: 24, child: Icon(Icons.person));
            }

            final data = snap.data!.data() as Map<String, dynamic>;
            final photo = data["photoUrl"] ?? "";

            return CircleAvatar(
              radius: 24,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty ? const Icon(Icons.person) : null,
            );
          },
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // BOUTON PRINCIPAL (Créateur / Participant / Non inscrit / Attente)
  // ---------------------------------------------------------------------------

  Widget _mainActionButton({
    required Activite activite,
    required bool isCreator,
    required bool inside,
    required bool waiting,
    required bool isFull,
    required Color color,
    required Color textColor,
  }) {
    String label;
    VoidCallback? onTap;
    Gradient gradient;

    if (isCreator) {
      label = "Modifier l’activité";
      gradient = LinearGradient(
        colors: [color.withOpacity(0.95), color.withOpacity(0.75)],
      );
      onTap = () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiviteModificationPage(activite: activite),
          ),
        );
        _load();
      };
    } else if (inside) {
      label = "Se désinscrire";
      gradient = const LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFFF97316)],
      );
      onTap = _toggleParticipation;
    } else if (waiting) {
      label = "En attente";
      gradient = const LinearGradient(colors: [Colors.grey, Colors.blueGrey]);
      onTap = null; // pas cliquable
    } else if (isFull) {
      // Activité complète, utilisateur ni participant ni en attente
      label = "Ajouter à la liste d’attente";
      gradient = const LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFFF97316)],
      );
      onTap = _toggleParticipation;
    } else {
      label = "Participer";
      gradient = const LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFFF97316)],
      );
      onTap = _toggleParticipation;
    }

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🧩 CHAT EMBARQUÉ (version mini, responsive dans la fiche)
// -----------------------------------------------------------------------------

class _EmbeddedActiviteChat extends StatefulWidget {
  final String activiteId;
  final Color categoryColor;

  const _EmbeddedActiviteChat({
    required this.activiteId,
    required this.categoryColor,
  });

  @override
  State<_EmbeddedActiviteChat> createState() => _EmbeddedActiviteChatState();
}

class _EmbeddedActiviteChatState extends State<_EmbeddedActiviteChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ActiviteService _service = ActiviteService();

  @override
  void initState() {
    super.initState();
    _service.markAsRead(widget.activiteId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final chatCol = FirebaseFirestore.instance
          .collection("activites")
          .doc(widget.activiteId)
          .collection("chat");

      await chatCol.add({
        "userId": uid,
        "message": txt,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _service.updateLastMessage(widget.activiteId, txt);

      setState(() {
        _controller.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      debugPrint("Erreur send mini chat : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.categoryColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Header mini chat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    "Chat de l’activité",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ActiviteChatPage(activiteId: widget.activiteId),
                      ),
                    );
                  },
                  child: const Text(
                    "Plein écran",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("activites")
                  .doc(widget.activiteId)
                  .collection("chat")
                  .orderBy("createdAt")
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  );
                }

                final docs = snap.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_scroll.hasClients) return;
                  _scroll.jumpTo(_scroll.position.maxScrollExtent);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Aucun message pour l’instant.\nLance la discussion !",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final userId = data["userId"];
                    final text = data["message"]?.toString() ?? "";
                    final ts = data["createdAt"] as Timestamp?;
                    final date = ts?.toDate();

                    if (userId == null || text.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(userId)
                          .get(),
                      builder: (_, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final u = userSnap.data!.data() as Map<String, dynamic>;
                        final prenom = u["firstName"] ?? "Profil";
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid;
                        final isMe = userId == currentUid;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? color.withOpacity(0.10)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.25),
                                width: 0.6,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prenom,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  text,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (date != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat("dd/MM HH:mm").format(date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Barre d'input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "Écrire un message...",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
