import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';
import '../groupe/groupe_chat_page.dart';
import '../groupe/groupe_service.dart';
import '../groupe/groupe_model.dart';

import '../activite/activite_chat_page.dart'; // si tu en as besoin ailleurs
import '../activite/activite_creation_page.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../theme/app_colors.dart';
import '../accueil/modal_post.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';
import '../settings/mon_agenda_page.dart';

class ChatItem {
  final String id;
  final String type; // "private", "groupe"
  final String title;
  final String subtitle;
  final String imageUrl;
  final DateTime lastTime;
  final String? otherUserId;
  final bool hasUnread;

  ChatItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.lastTime,
    this.otherUserId,
    this.hasUnread = false,
  });
}

class MessageriePage extends StatefulWidget {
  const MessageriePage({super.key});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  final GroupeService groupeService = GroupeService();

  List<ChatItem> allChats = [];

  bool _joining = false;
  bool _requesting = false;

  int selectedTab = 0;

  late AnimationController _tabController;
  late Animation<double> _slider;

  // 🔍 Recherche globale
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  // 🎯 Filtres centres d’intérêt pour l’onglet Salons
  final Set<String> selectedInterestsFilter = {};

  // Liste d’intérêts dispo pour le filtre
  final Map<String, List<String>> _allInterests = const {
    'Sports': [
      'Football',
      'Basket-ball',
      'Tennis',
      'Running',
      'Natation',
      'Cyclisme',
      'Aviron',
      'Yoga',
      'Arts martiaux',
      'Escalade',
      'Surf',
      'Ski',
      'Fitness',
      'Danse',
      'Boxe',
      'Paddle',
      'Golf',
      'Volleyball',
      'Rugby',
    ],
    'Culture': [
      'Cinéma',
      'Lecture',
      'Bandes dessinées',
      'Philosophie',
      'Musées',
      'Développement personnel',
      'Histoire',
      'Poésie',
    ],
    'Voyages': [
      'Découverte',
      'Road trip',
      'Camping',
      'Trekking',
      'Croisière',
      'Tourisme local',
      'Nature',
      'Voyages gastronomiques',
    ],
    'Musique': [
      'Rock',
      'Pop',
      'Jazz',
      'Classique',
      'Electro',
      'Rap',
      'Reggae',
      'R’n’B',
      'Soul',
      'Funk',
    ],
  };

  // 🔢 Compteur d'activités futures pour l'Agenda
  int _futureActivitiesCount = 0;

  @override
  void initState() {
    super.initState();

    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slider = Tween<double>(begin: 0, end: 0).animate(_tabController);

    _loadAllChats();
    _loadFutureActivitiesCount(); // ← charge le compteur Agenda
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAllChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // 🔥 Compteurs non-lus pour onglets
  // ----------------------------------------------------------
  int get _unreadPrivateCount =>
      allChats.where((c) => c.type == "private" && c.hasUnread).length;

  int get _unreadSalonCount =>
      allChats.where((c) => c.type == "groupe" && c.hasUnread).length;

  // ----------------------------------------------------------
  // 🔥 Compteur d'activités futures (Agenda)
  // ----------------------------------------------------------
  Future<void> _loadFutureActivitiesCount() async {
    try {
      final uid = user.uid;
      final now = DateTime.now();

      final snap = await FirebaseFirestore.instance
          .collection("activites")
          .where("participants", arrayContains: uid)
          .get();

      int count = 0;
      for (var doc in snap.docs) {
        final data = doc.data();
        final rawDate = data["date"];
        if (rawDate is Timestamp) {
          final date = rawDate.toDate();
          if (date.isAfter(now)) {
            count++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _futureActivitiesCount = count;
        });
      }
    } catch (e) {
      debugPrint("Erreur _loadFutureActivitiesCount: $e");
    }
  }

  // ----------------------------------------------------------
  // 🔥 Charger toutes les conversations (private + groupes)
  // ----------------------------------------------------------
  Future<void> _loadAllChats() async {
    final uid = user.uid;
    List<ChatItem> finalList = [];

    try {
      // ------------------------- 🔵 PRIVATE CHATS -------------------------
      final privateQuery = await FirebaseFirestore.instance
          .collection("conversations")
          .where("users", arrayContains: uid)
          .get();

      for (var doc in privateQuery.docs) {
        final data = doc.data();

        final users = List<String>.from(data["users"] ?? []);
        final otherUserId = users.firstWhere(
          (u) => u != uid,
          orElse: () => "unknown",
        );

        bool hasUnread = false;
        if (data["unreadBy"] is List) {
          hasUnread = (data["unreadBy"] as List).contains(uid);
        }

        // 🔥 Récupérer les infos réelles du user
        String otherName = "Utilisateur";
        String otherPhoto = "";

        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(otherUserId)
            .get();

        if (userDoc.exists) {
          final dataUser = userDoc.data()!;
          // adapte aux champs de ta collection users
            // 🔥 les bonnes clés Firestore
          otherName = dataUser["firstName"] ?? "Utilisateur";
          otherPhoto = dataUser["photoUrl"] ?? "";
        }

        final lastTime = (data["lastTime"] is Timestamp)
            ? (data["lastTime"] as Timestamp).toDate()
            : DateTime(2000);

        finalList.add(
          ChatItem(
            id: doc.id,
            type: "private",
            title: otherName,
            subtitle: (data["lastMessage"] ?? "").toString(),
            imageUrl: otherPhoto,
            lastTime: lastTime,
            otherUserId: otherUserId,
            hasUnread: hasUnread,
          ),
        );
      }

      // ------------------------- 🟠 GROUPES -------------------------
      final myGroups = await groupeService.getMyGroups();

      for (var g in myGroups) {
        final gDoc = await FirebaseFirestore.instance
            .collection("groupes")
            .doc(g.id)
            .get();

        bool hasUnread = false;
        final gData = gDoc.data();
        if (gData != null && gData["unreadBy"] is List) {
          hasUnread = (gData["unreadBy"] as List).contains(uid);
        }

        finalList.add(
          ChatItem(
            id: g.id,
            type: "groupe",
            title: g.nom,
            subtitle: g.lastMessage,
            imageUrl: g.photoUrl,
            lastTime: g.lastTime ?? DateTime(2000),
            hasUnread: hasUnread,
          ),
        );
      }

      finalList.sort((a, b) => b.lastTime.compareTo(a.lastTime));

      if (mounted) {
        setState(() => allChats = finalList);
      }
    } catch (e) {
      debugPrint("Erreur _loadAllChats: $e");
    }
  }

  // ----------------------------------------------------------
  // 🔥 Barre de recherche
  // ----------------------------------------------------------
  Widget _buildSearchBar() {
    final isSalonTab = selectedTab == 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value.trim()),
        decoration: InputDecoration(
          hintText: isSalonTab
              ? "Rechercher un salon ou un centre d’intérêt..."
              : "Rechercher une conversation...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isSalonTab
              ? IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _openFilterBottomSheet,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔥 Modal filtres centres d’intérêt (Salons)
  // ----------------------------------------------------------
  Future<void> _openFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filtrer par centres d’intérêt",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _allInterests.entries.map((entry) {
                            final cat = entry.key;
                            final items = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    cat,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: items.map((interest) {
                                    final selected = selectedInterestsFilter
                                        .contains(interest);
                                    return FilterChip(
                                      label: Text(interest),
                                      selected: selected,
                                      onSelected: (v) {
                                        setModalState(() {
                                          if (selected) {
                                            selectedInterestsFilter.remove(
                                              interest,
                                            );
                                          } else {
                                            selectedInterestsFilter.add(
                                              interest,
                                            );
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedInterestsFilter.clear();
                            });
                            setState(() {});
                          },
                          child: const Text("Réinitialiser"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Fermer"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🔥 Tabs animés Messagerie / Salons
  // ----------------------------------------------------------
  Widget _buildTabs() {
    double width = MediaQuery.of(context).size.width;
    double tabWidth = (width - 40) / 2;

    final msgLabel = _unreadPrivateCount > 0
        ? "Messagerie (${_unreadPrivateCount})"
        : "Messagerie";
    final salonLabel = _unreadSalonCount > 0
        ? "Salons (${_unreadSalonCount})"
        : "Salons";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _slider,
            builder: (_, __) => Positioned(
              left: _slider.value * tabWidth,
              top: 0,
              bottom: 0,
              width: tabWidth,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFFFB347)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeTab(0),
                  child: Center(
                    child: Text(
                      msgLabel,
                      style: TextStyle(
                        color: selectedTab == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeTab(1),
                  child: Center(
                    child: Text(
                      salonLabel,
                      style: TextStyle(
                        color: selectedTab == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changeTab(int index) {
    setState(() => selectedTab = index);

    double end = index == 0 ? 0 : 1;

    _slider = Tween<double>(
      begin: _slider.value,
      end: end,
    ).animate(_tabController);
    _tabController.forward(from: 0);
  }

  // ----------------------------------------------------------
  // 🔥 Liste Salons (groupes) — salons inscrits en haut
  // ----------------------------------------------------------
  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("groupes").snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text("Erreur lors du chargement des salons."),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("Aucun salon pour le moment."));
        }

        final q = searchQuery.toLowerCase();
        final uid = user.uid;

        final filteredDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final nom = (data["nom"] ?? "Salon").toString();
          final description = (data["description"] ?? "").toString();
          final interets = List<String>.from(data["interets"] ?? []);

          bool matchSearch = true;
          if (q.isNotEmpty) {
            final searchIn =
                (nom + " " + description + " " + interets.join(" "))
                    .toLowerCase();
            matchSearch = searchIn.contains(q);
          }

          bool matchInterests = true;
          if (selectedInterestsFilter.isNotEmpty) {
            matchInterests = interets.any(
              (i) => selectedInterestsFilter.contains(i),
            );
          }

          return matchSearch && matchInterests;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Text("Aucun salon ne correspond à la recherche."),
          );
        }

        // 👉 Salons où je suis membre en haut
        filteredDocs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final am = List<String>.from(da["membres"] ?? []).contains(uid);
          final bm = List<String>.from(db["membres"] ?? []).contains(uid);
          if (am == bm) return 0;
          return am ? -1 : 1;
        });

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (_, i) {
            final d = filteredDocs[i];
            final data = d.data() as Map<String, dynamic>;
            final id = d.id;

            final nom = (data["nom"] ?? "Salon").toString();
            final description = (data["description"] ?? "").toString();
            final photoUrl = (data["photoUrl"] ?? "").toString();
            final membres = List<String>.from(data["membres"] ?? []);
            final interets = List<String>.from(data["interets"] ?? []);
            final isPublic = (data["isPublic"] ?? true) as bool;

            final pending = List<String>.from(data["pendingRequests"] ?? []);
            final bool alreadyRequested = pending.contains(user.uid);
            final isMember = membres.contains(user.uid);

            final interetText = interets.isEmpty
                ? ""
                : interets.take(5).join(" • ");

            final unreadBy = List<String>.from(data["unreadBy"] ?? []);
            final bool hasUnread = unreadBy.contains(uid);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFFF5EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: Colors.orange.shade100,
                      child: photoUrl.isNotEmpty
                          ? Image.network(photoUrl, fit: BoxFit.cover)
                          : const Icon(Icons.groups, color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // TITRE + DESCRIPTION + INTERETS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre (MAJ + gras)
                        Text(
                          nom.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                        // Description
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        if (interetText.isNotEmpty)
                          Text(
                            interetText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // COLONNE DROITE : Non-lu / membres / bouton
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF4C630), Color(0xFFF97316)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Non-lu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (hasUnread) const SizedBox(height: 6),
                      Text(
                        "${membres.length} membres",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isMember)
                        _discuterButton(id)
                      else if (isPublic)
                        _joinButton(id)
                      else
                        _requestButton(id, alreadyRequested),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _discuterButton(String groupId) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupeChatPage(groupeId: groupId)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          "Discuter",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _joinButton(String groupId) {
    return InkWell(
      onTap: () async {
        if (_joining) return;
        _joining = true;
        setState(() {});

        try {
          await groupeService.rejoindreGroupe(groupId);
          await _loadAllChats();

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupeChatPage(groupeId: groupId),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
        } finally {
          _joining = false;
          if (mounted) setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD422F7), Color(0xFFFFA726)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          "Rejoindre",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _requestButton(String groupId, bool alreadyRequested) {
    if (alreadyRequested) {
      return OutlinedButton(
        onPressed: null,
        child: const Text("Demandé", style: TextStyle(fontSize: 12)),
      );
    }

    return InkWell(
      onTap: () async {
        if (_requesting) return;
        _requesting = true;
        setState(() {});

        try {
          final uid = user.uid;
          final groupRef = FirebaseFirestore.instance
              .collection("groupes")
              .doc(groupId);

          await groupRef.collection("demandes").doc(uid).set({
            "uid": uid,
            "sentAt": FieldValue.serverTimestamp(),
          });

          await groupRef.update({
            "pendingRequests": FieldValue.arrayUnion([uid]),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Demande envoyée aux administrateurs."),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
          }
        } finally {
          _requesting = false;
          if (mounted) setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepPurple),
        ),
        child: const Text(
          "Demander",
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔥 BUILD UI GLOBAL
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAEF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),

        // 🔸 Agenda collé à l’icône, relié à "Mon Agenda"
        leadingWidth: 180,
        leading: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.event_available, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonAgendaPage()),
                );
              },
            ),
            Flexible(
              child: Text(
                "Agenda (${_futureActivitiesCount})",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        title: const Text(
          "Discussion",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
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
                ).then((_) => _loadAllChats());
              }
              if (res == "groupe") {
                Navigator.pushNamed(
                  context,
                  "/create_group",
                ).then((_) => _loadAllChats());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
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
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, "/home");
          if (index == 1) Navigator.pushReplacementNamed(context, "/reseau");
          if (index == 3) Navigator.pushReplacementNamed(context, "/activites");
          if (index == 4) Navigator.pushReplacementNamed(context, "/events");
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabs(),
            const SizedBox(height: 6),
            Expanded(
              child: selectedTab == 0
                  ? _buildConversationsList()
                  : _buildGroupsList(),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔥 LISTE DES CHATS (Messagerie = private uniquement)
  //   + suppression de chat
  // ----------------------------------------------------------
  Widget _buildConversationsList() {
    // On ne garde que les conversations privées
    final privateChats = allChats
        .where((c) => c.type == "private")
        .toList(growable: false);

    if (privateChats.isEmpty) {
      return const Center(child: Text("Aucune conversation."));
    }

    final q = searchQuery.toLowerCase();

    final filtered = q.isEmpty
        ? privateChats
        : privateChats.where((c) {
            final haystack = (c.title + " " + c.subtitle).toLowerCase();
            return haystack.contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text("Aucune conversation ne correspond à la recherche."),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, index) {
        final c = filtered[index];

        return Dismissible(
          key: ValueKey("chat_${c.id}"),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Supprimer la conversation ?"),
                    content: const Text(
                      "Cette conversation sera supprimée pour les deux utilisateurs.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Annuler"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Supprimer",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) async {
            await _deleteChat(c);
          },
          child: ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: c.imageUrl.isNotEmpty
                  ? NetworkImage(c.imageUrl)
                  : null,
              child: c.imageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
              backgroundColor: Colors.deepPurple.shade200,
            ),
            title: Text(
              c.title, // prénom / nom de l'autre utilisateur
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    "${c.subtitle.isEmpty ? "Conversation" : c.subtitle} • "
                    "${_formatMessageTime(c.lastTime)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (c.hasUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF4C630), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Non-lu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => _openChat(c),
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();

    // Aujourd’hui → juste l’heure
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return "${time.hour.toString().padLeft(2, '0')}:"
          "${time.minute.toString().padLeft(2, '0')}";
    }

    // Autre jour → jj/mm hh:mm
    return "${time.day.toString().padLeft(2, '0')}/"
        "${time.month.toString().padLeft(2, '0')} "
        "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}";
  }

  // ----------------------------------------------------------
  // 🔥 Titre custom selon type (PRIVATE / GROUPE) – utilisé ailleurs si besoin
  // ----------------------------------------------------------

  // ----------------------------------------------------------
  // 🔥 Ouverture d'un chat + marquer "non-lu" comme lu
  // ----------------------------------------------------------
  Future<void> _openChat(ChatItem c) async {
    final uid = user.uid;

    try {
      if (c.type == "private") {
        await FirebaseFirestore.instance
            .collection("conversations")
            .doc(c.id)
            .update({
              "unreadBy": FieldValue.arrayRemove([uid]),
            });
      } else if (c.type == "groupe") {
        await FirebaseFirestore.instance.collection("groupes").doc(c.id).update(
          {
            "unreadBy": FieldValue.arrayRemove([uid]),
          },
        );
      }
    } catch (_) {
      // on évite de crasher si le champ n'existe pas encore
    }

    Widget page;

    switch (c.type) {
      case "private":
        page = ChatPage(conversationId: c.id, otherUserId: c.otherUserId!);
        break;
      case "groupe":
        page = GroupeChatPage(groupeId: c.id);
        break;
      default:
        return;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    _loadAllChats();
    _loadFutureActivitiesCount(); // si besoin de rafraîchir après retour
  }

  // ----------------------------------------------------------
  // 🔥 Suppression d'un chat privé
  // ----------------------------------------------------------
  Future<void> _deleteChat(ChatItem c) async {
    if (c.type != "private") return;
    try {
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(c.id)
          .delete();
      _loadAllChats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression : $e")),
      );
    }
  }
}
