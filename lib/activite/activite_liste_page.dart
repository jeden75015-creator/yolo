// -----------------------------------------------------------------------------
// 📄 PAGE : Liste des Activités — VERSION FINALE
//  - Header : Agenda / Activités / Créer (menu complet)
//  - Barre de recherche + bouton filtre à droite
//  - Cartes : bandeau haut = couleur catégorie (titre + catégorie)
//             reste de la carte = fond pastel clair
//  - Liste d’attente + position dans la liste (badges)
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'activite_model.dart';
import 'activite_service.dart';
import 'activite_fiche_page.dart';
import 'categorie_data.dart';
import 'modal_helpers.dart';
import 'activite_creation_page.dart';
import '../accueil/modal_post.dart';
import 'package:yolo/widgets/custom_bottom_navbar.dart';
import 'package:yolo/settings/mon_agenda_page.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';

class ActiviteListePage extends StatefulWidget {
  const ActiviteListePage({super.key});

  @override
  State<ActiviteListePage> createState() => _ActiviteListePageState();
}

class _ActiviteListePageState extends State<ActiviteListePage> {
  final ActiviteService _service = ActiviteService();

  late StreamSubscription sub;

  List<Activite> activites = [];
  List<Activite> filtered = [];

  String search = "";
  String? filtreCategorie;
  String? filtreRegion;
  String filtreDate = "all";

  bool loading = true;

  @override
  void initState() {
    super.initState();

    // 🔥 Flux temps réel
    sub = FirebaseFirestore.instance
        .collection("activites")
        .orderBy("date")
        .snapshots()
        .listen((snap) {
          final list = snap.docs
              .map((d) {
                try {
                  return Activite.fromFirestore(d);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Activite>()
              .toList();

          final now = DateTime.now();
          activites = list.where((a) => a.date.isAfter(now)).toList();

          _applyFilters();
          setState(() => loading = false);
        });
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🔍 FILTRES
  // ---------------------------------------------------------------------------
  void _applyFilters() {
    final now = DateTime.now();

    filtered = activites.where((a) {
      if (a.titre.isEmpty) return false;

      if (search.isNotEmpty &&
          !a.titre.toLowerCase().contains(search.toLowerCase())) {
        return false;
      }

      if (filtreCategorie != null && filtreCategorie != a.categorie) {
        // NOTE : si tu ajoutes "Sauvegardé" comme valeur spéciale,
        // tu peux adapter ici la logique.
        return false;
      }

      if (filtreRegion != null && filtreRegion != a.region) {
        return false;
      }

      if (filtreDate == "today") {
        final today = DateTime(now.year, now.month, now.day);
        final day = DateTime(a.date.year, a.date.month, a.date.day);
        if (day != today) return false;
      }

      if (filtreDate == "week") {
        final week = now.add(const Duration(days: 7));
        if (a.date.isAfter(week)) return false;
      }

      return true;
    }).toList();

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // 📅 Format date pour badge
  // ---------------------------------------------------------------------------
  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(d.year, d.month, d.day);

    if (target == today) return "Aujourd’hui";
    if (target == tomorrow) return "Demain";

    const jours = [
      "",
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche",
    ];

    return "${jours[d.weekday]} ${d.day}/${d.month}";
  }

  // ---------------------------------------------------------------------------
  // 🔽 PANEL DE FILTRES (bottom sheet)
  // ---------------------------------------------------------------------------
  void _openFilterPanel() {
    String tempDate = filtreDate;
    String? tempCategorie = filtreCategorie;
    String? tempRegion = filtreRegion;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Filtres",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // DATE
                    const Text(
                      "Date",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      children: [
                        _filterButton(
                          "Aujourd’hui",
                          tempDate == "today",
                          () => setModal(() => tempDate = "today"),
                        ),
                        _filterButton(
                          "Cette semaine",
                          tempDate == "week",
                          () => setModal(() => tempDate = "week"),
                        ),
                        _filterButton(
                          "Toutes",
                          tempDate == "all",
                          () => setModal(() => tempDate = "all"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // CATEGORIE
                    const Text(
                      "Catégorie",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      children: [
                        ...CategorieData.categories.keys.map(
                          (c) => _filterButton(
                            c,
                            tempCategorie == c,
                            () => setModal(() => tempCategorie = c),
                          ),
                        ),
                        // Si tu as un bouton "Sauvegardé", tu peux le brancher ici :
                        // _filterButton(
                        //   "Sauvegardé",
                        //   tempCategorie == "saved",
                        //   () => setModal(() => tempCategorie = "saved"),
                        // ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // REGION
                    const Text(
                      "Région",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String?>(
                      value: tempRegion,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text("Toutes les régions"),
                        ),
                        DropdownMenuItem(
                          value: "Guadeloupe",
                          child: Text("Guadeloupe"),
                        ),
                        DropdownMenuItem(
                          value: "Martinique",
                          child: Text("Martinique"),
                        ),
                        DropdownMenuItem(
                          value: "Guyane",
                          child: Text("Guyane"),
                        ),
                        DropdownMenuItem(
                          value: "Réunion",
                          child: Text("Réunion"),
                        ),
                        DropdownMenuItem(
                          value: "Mayotte",
                          child: Text("Mayotte"),
                        ),
                        DropdownMenuItem(
                          value: "Occitanie",
                          child: Text("Occitanie"),
                        ),
                        DropdownMenuItem(
                          value: "Auvergne-Rhône-Alpes",
                          child: Text("Auvergne-Rhône-Alpes"),
                        ),
                        DropdownMenuItem(
                          value: "Île-de-France",
                          child: Text("Île-de-France"),
                        ),
                      ],
                      onChanged: (v) => setModal(() => tempRegion = v),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              filtreCategorie = null;
                              filtreRegion = null;
                              filtreDate = "all";
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            child: const Text("Réinitialiser"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 254, 172, 31),
                            ),
                            onPressed: () {
                              filtreCategorie = tempCategorie;
                              filtreRegion = tempRegion;
                              filtreDate = tempDate;

                              Navigator.pop(context);
                              _applyFilters();
                            },
                            child: const Text("Appliquer"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Bouton pill pour les filtres
  Widget _filterButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [
                    Color(0xFFF97316), // orange
                    Color(0xFFE91E63), // fuchsia
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI PRINCIPALE
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, "/home");
          if (i == 1) Navigator.pushReplacementNamed(context, "/reseau");
          if (i == 2) Navigator.pushReplacementNamed(context, "/chat");
          if (i == 3) return;
          if (i == 4) Navigator.pushReplacementNamed(context, "/events");
        },
      ),
      body: SafeArea(
        child: Column(children: [_header(), _searchBar(), _content()]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER (Agenda / Activités / Créer)
  // ---------------------------------------------------------------------------
  Widget _header() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    int myCount = 0;
    if (uid != null) {
      myCount = activites.where((a) => a.participants.contains(uid)).length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          /// 📅 Agenda (gauche)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonAgendaPage()),
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.event_available,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  "Agenda${myCount > 0 ? " ($myCount)" : ""}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          /// 🔥 Titre
          const Text(
            "Activités",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const Spacer(),

          /// 🔵 BOUTON CRÉER (menu complet)
          GestureDetector(
            onTap: () async {
              final res = await showModalPostSelector(context);
              if (res == null) return;

              if (res == "post") {
                Navigator.pushNamed(context, "/create_post");
              }

              if (res == "poll") {
                Navigator.pushNamed(context, "/create_poll");
              }

              if (res == "activite") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActiviteCreationPage(),
                  ),
                ).then((_) => _applyFilters());
              }

              if (res == "groupe") {
                Navigator.pushNamed(
                  context,
                  "/create_group",
                ).then((_) => _applyFilters());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "Créer",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH BAR + BOUTON FILTRE À DROITE
  // ---------------------------------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) {
                search = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: "Rechercher une activité...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton filtre juste à droite
          GestureDetector(
            onTap: _openFilterPanel,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.filter_alt_rounded,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LISTE DES ACTIVITÉS
  // ---------------------------------------------------------------------------
  Widget _content() {
    if (loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "Aucune activité trouvée",
            style: TextStyle(
              color: Colors.black87.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 255,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _card(context, filtered[i]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🌟 CARTE ACTIVITÉ — Bandeau catégorie + fond pastel + liste d’attente
  // ---------------------------------------------------------------------------
  Widget _card(BuildContext context, Activite a) {
    final Map<String, dynamic> cat =
        CategorieData.categories[a.categorie] ?? {};

    final Color catColor = (cat["color"] as Color?) ?? Colors.deepPurple;
    final Color textColor = (cat["textColor"] as Color?) ?? Colors.white;
    final String emoji = (cat["emoji"] as String?) ?? "✨";

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bool isInside = a.participants.contains(uid);
    final bool isFull = a.participants.length >= a.maxParticipants;

    // Liste d’attente (on suppose que Activite a listeAttente: List<String>?)
    final List<String> waitingList = a.participantsAttente;
    final int waitingCount = waitingList.length;
    final int myWaitingIndex = waitingList.indexOf(uid);


    return GestureDetector(
      onTap: () => openActiviteFicheModal(context, a.id),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double baseWidth = 255;
          final double scale = (constraints.maxWidth / baseWidth).clamp(
            0.65,
            1.0,
          );

          final double titleSize = 16 * scale;
          final double infoSize = 12 * scale;
          final double iconSize = 16 * scale;

          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                // Fond pastel 3 couleurs très clair
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFFBEB),
                    Color(0xFFFFF5EE),
                    Color(0xFFEFF6FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----------------------------------------------------
                  // IMAGE + BADGE DATE
                  // ----------------------------------------------------
                  Stack(
                    children: [
                      SizedBox(
                        height: 120 * scale,
                        width: double.infinity,
                        child: a.photoUrl.isNotEmpty
                            ? Image.network(
                                StorageHelper.convert(a.photoUrl),
                                fit: BoxFit.cover,
                              )
                            : Container(color: Colors.grey.shade300),
                      ),
                      Positioned(
                        top: 10 * scale,
                        right: 10 * scale,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10 * scale,
                            vertical: 5 * scale,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF4C630), Color(0xFFF97316)],
                            ),
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                          child: Text(
                            _formatDate(a.date),
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11 * scale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ----------------------------------------------------
                  // BANDEAU CATÉGORIE (titre + catégorie, fond catColor)
                  // ----------------------------------------------------
                  Container(
                    width: double.infinity,
                    color: catColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 8 * scale,
                    ),
                    child: Column(
                      children: [
                        // Titre
                        Text(
                          a.titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: titleSize,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        // Catégorie
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10 * scale,
                            vertical: 4 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14 * scale),
                          ),
                          child: Text(
                            "$emoji ${a.categorie}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ----------------------------------------------------
                  // CONTENU PASTEL : infos, adresse, organisateur, bouton
                  // ----------------------------------------------------
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(10 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4 * scale),

                          // DATE
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: iconSize,
                                color: const Color(0xFFF59E0B),
                              ),
                              SizedBox(width: 6 * scale),
                              Expanded(
                                child: Text(
                                  _formatDate(a.date),
                                  style: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontSize: infoSize,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4 * scale),

                          // HEURE
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: iconSize,
                                color: const Color(0xFFE91E63),
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                "${a.date.hour.toString().padLeft(2, '0')}h${a.date.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: infoSize,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4 * scale),

                          // DURÉE
                          if (a.duree != null && a.duree!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.timelapse,
                                  size: iconSize,
                                  color: const Color(0xFF9C27B0),
                                ),
                                SizedBox(width: 6 * scale),
                                Text(
                                  a.duree!,
                                  style: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontSize: infoSize,
                                  ),
                                ),
                              ],
                            ),

                          if (a.duree != null && a.duree!.isNotEmpty)
                            SizedBox(height: 4 * scale),

                          // ADRESSE + REGION
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: iconSize,
                                color: const Color(0xFF1E88E5),
                              ),
                              SizedBox(width: 6 * scale),
                              Expanded(
                                child: Text(
                                  "${a.adresse}, ${a.region}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontSize: infoSize,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4 * scale),

                          // PARTICIPANTS
                          Row(
                            children: [
                              Icon(
                                Icons.group,
                                size: iconSize,
                                color: const Color(0xFFF57C00),
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                "${a.participants.length} / ${a.maxParticipants} participants",
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: infoSize,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4 * scale),

                          // LISTE D'ATTENTE (BADGES)
                          if (waitingCount > 0)
                            Wrap(
                              spacing: 6 * scale,
                              runSpacing: 4 * scale,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * scale,
                                    vertical: 4 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF97316),
                                        Color(0xFFE91E63),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      14 * scale,
                                    ),
                                  ),
                                  child: Text(
                                    "Liste d’attente : $waitingCount",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (myWaitingIndex >= 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF6366F1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        14 * scale,
                                      ),
                                    ),
                                    child: Text(
                                      "Votre position : ${myWaitingIndex + 1}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                          SizedBox(height: 8 * scale),

                          // ORGANISÉ PAR
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection("users")
                                .doc(a.createurId)
                                .get(),
                            builder: (context, snap) {
                              if (!snap.hasData || !snap.data!.exists) {
                                return SizedBox(height: 24 * scale);
                              }

                              final d =
                                  snap.data!.data() as Map<String, dynamic>;
                              final prenom = d["firstName"] ?? "Profil";
                              final photo = d["photoUrl"] ?? "";

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Organisé par ",
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 14 * scale,
                                    backgroundImage: photo.isNotEmpty
                                        ? NetworkImage(photo)
                                        : null,
                                    backgroundColor: photo.isEmpty
                                        ? Colors.white
                                        : null,
                                    child: photo.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            size: 14 * scale,
                                            color: Colors.grey.shade800,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 6 * scale),
                                  Text(
                                    prenom.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.grey.shade900,
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          SizedBox(height: 12 * scale),

                          // BOUTON PRINCIPAL
                          GestureDetector(
                            onTap: () async {
                              if (isInside) {
                                await _service.quitterActivite(a.id, uid);
                              } else if (!isFull) {
                                await _service.rejoindreActivite(a.id, uid);
                              }
                            },
                            child: Container(
                              height: 38 * scale,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12 * scale),
                                gradient: isFull
                                    ? null
                                    : isInside
                                    ? LinearGradient(
                                        colors: [
                                          catColor,
                                          catColor.withOpacity(0.6),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFF97316),
                                          Color(0xFFE91E63),
                                        ],
                                      ),
                                color: isFull
                                    ? Colors.white.withOpacity(0.7)
                                    : null,
                                border: isFull
                                    ? Border.all(
                                        color: Colors.grey.shade500,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  isFull
                                      ? "Complet => liste d’attente"
                                      : isInside
                                      ? "Inscrit"
                                      : "Participer",
                                  style: TextStyle(
                                    color: isFull
                                        ? Colors.indigo.shade700
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
