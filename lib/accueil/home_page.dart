// Flutter imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ---- Posts ----
import 'package:yolo/accueil/post/post_model.dart';
import 'package:yolo/accueil/post/post_service.dart';
import 'package:yolo/accueil/post/post/post_card.dart';
import 'package:yolo/accueil/post/poll/poll_card.dart';

// ---- Activités ----
import '../activite/activite_model.dart';
import '../activite/activite_service.dart';
import '../activite/activite_fiche_page.dart';
import '../activite/categorie_data.dart';
import '../activite/activite_creation_page.dart';
import '../groupe/groupe_service.dart';
// ---- UI ----
import '../widgets/custom_bottom_navbar.dart';

// ---- Modal ----
import '../accueil/modal_post.dart';

// ---- Side Gradient ----
const LinearGradient sideGradient = LinearGradient(
  colors: [
    Color(0xFFFFF7E0),
    Color(0xFFFFEBC5),
    Color(0xFFFFE1B2),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ActiviteService _activiteService = ActiviteService();
  final PostService _postService = PostService();
  // final GroupeService _groupeService = GroupeService();


  // ======================================================================
  // FORMATAGE JOUR
  // ======================================================================
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);

    final diff = target.difference(today).inDays;

    if (diff == 0) return "Aujourd’hui";
    if (diff == 1) return "Demain";

    if (diff >= 2 && diff <= 6) {
      const days = [
        "Lundi",
        "Mardi",
        "Mercredi",
        "Jeudi",
        "Vendredi",
        "Samedi",
        "Dimanche"
      ];
      return days[target.weekday - 1];
    }

    return DateFormat("dd MMM", "fr_FR").format(d);
  }

  // ======================================================================
  // BUILD
  // ======================================================================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final user = FirebaseAuth.instance.currentUser!;

    // ======================================================================
    // FEED + ACTIVITÉS
    // ======================================================================
    final feedColumn = StreamBuilder<List<Post>>(
      stream: _postService.streamFeed(),
      builder: (context, postSnap) {
        if (!postSnap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final posts = postSnap.data!;

        return FutureBuilder<List<Activite>>(
          future: _activiteService.getActivites(),
          builder: (context, actSnap) {
            if (!actSnap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              );
            }

            final activites = actSnap.data!;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final oneWeekLater = today.add(const Duration(days: 7));
            final postLimit = now.subtract(const Duration(hours: 48));

            // Activités à venir
            final upcomingWeek = activites.where((a) {
              final d = DateTime(a.date.year, a.date.month, a.date.day);
              return !d.isBefore(today) && !d.isAfter(oneWeekLater);
            }).toList();

            // Posts des dernières 48h
            final recentPosts =
                posts.where((p) => p.date.isAfter(postLimit)).toList();

            // Fusion
            final items = <dynamic>[
              ...recentPosts,
              ...upcomingWeek,
            ];

            // Tri par date décroissante
            items.sort((a, b) {
              final da = (a is Activite) ? a.date : (a as Post).date;
              final db = (b is Activite) ? b.date : (b as Post).date;
              return db.compareTo(da);
            });

            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                padding: const EdgeInsets.only(
                    bottom: 80, top: 15, left: 10, right: 10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (item is Activite) return _buildActiviteCard(item);
                  if (item is Post) {
                    return item.isPoll
                        ? PollCard(post: item)
                        : PostCard(post: item);
                  }

                  return const SizedBox.shrink();
                },
              ),
            );
          },
        );
      },
    );

    // ======================================================================
    // PAGE
    // ======================================================================
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // ------------------------------------------------------------------
        // 🔥 HEADER complet (Paramètres + Notifications badge + Publier)
        // ------------------------------------------------------------------
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 244, 198, 48),
                  Color(0xFFF97316),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // BOUTON PARAMÈTRES
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 26),
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),

          // TITRE YOLO
          title: const Text(
            "YOLO",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // ACTIONS
          actions: [
            // 🔔 Notifications avec badge nombre
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, snap) {
                int unreadCount = 0;

                if (snap.hasData) {
                  unreadCount = snap.data!.docs.length;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/notifications");
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications,
                            color: Colors.white, size: 28),

                        if (unreadCount > 0)
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 20, minHeight: 20),
                              child: Center(
                                child: Text(
                                  unreadCount > 99
                                      ? "99+"
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 🔵 Bouton Publier
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton(
                onPressed: () async {
                  final choice = await showModalPostSelector(context);

                  if (choice == null) return;

                  if (choice == "post") {
                    Navigator.pushNamed(context, "/create_post");
                  } else if (choice == "poll") {
                    Navigator.pushNamed(context, "/create_poll");
                  } else if (choice == "activite") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActiviteCreationPage(),
                      ),
                    );
                  } else if (choice == "groupe") {
                    // 🔥 Route corrigée ici
                    Navigator.pushNamed(context, "/create_group");
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Publier",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ------------------------------------------------------------------
        // NAVBAR BAS
        // ------------------------------------------------------------------
        bottomNavigationBar: CustomBottomNavbar(
          currentIndex: 0,
          onTap: (i) {
            if (i == 0) return;
            if (i == 1) Navigator.pushReplacementNamed(context, "/reseau");
            if (i == 2) Navigator.pushReplacementNamed(context, "/chat");
            if (i == 3) Navigator.pushReplacementNamed(context, "/activites");
            if (i == 4) Navigator.pushReplacementNamed(context, "/events");
          },
        ),
        
        
        // ------------------------------------------------------------------
        // FEED + SIDEBARS
        // ------------------------------------------------------------------
        body: isMobile
            ? feedColumn
            : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                        decoration:
                            const BoxDecoration(gradient: sideGradient)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: feedColumn,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                        decoration:
                            const BoxDecoration(gradient: sideGradient)),
                  ),
                ],
              ),
      ),
    );
  }

  // ======================================================================
  // WIDGET ACTIVITÉ CARD
  // ======================================================================
  Widget _buildActiviteCard(Activite a) {
    final info = CategorieData.categories[a.categorie];
    final emoji = info?["emoji"] ?? "✨";
    final Color catColor = info?["color"] ?? Colors.deepPurple;

    final dayLabel = _dayLabel(a.date);
    final hour =
        "${a.date.hour.toString().padLeft(2, '0')}h${a.date.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ActiviteFichePage(activiteId: a.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: a.photoUrl.isNotEmpty
                    ? Image.network(a.photoUrl, fit: BoxFit.cover)
                    : Container(
                        color: catColor.withOpacity(0.5),
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 60, color: Colors.white70),
                        ),
                      ),
              ),

              // Dégradé
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Catégorie
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text("$emoji ${a.categorie}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                ),
              ),

              // Jour
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dayLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // Infos
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${a.adresse}, ${a.region}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(hour,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
