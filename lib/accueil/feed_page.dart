import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

// ---- Activités ----
import 'package:yolo/activite/activite_service.dart';
import 'package:yolo/activite/activite_model.dart';
import 'package:yolo/activite/activite_fiche_page.dart';
import 'package:yolo/activite/categorie_data.dart';
import 'package:yolo/activite/modal_helpers.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';
// ---- UI ----
import 'package:yolo/widgets/custom_app_bar.dart';
import 'package:yolo/widgets/custom_bottom_navbar.dart';

// ---- Posts ----
import 'package:yolo/accueil/modal_post.dart';
import 'package:yolo/accueil/post/post_service.dart';
import 'package:yolo/accueil/post/post_model.dart';
import 'package:yolo/accueil/post/post/post_card.dart';
import 'package:yolo/accueil/post/poll/poll_card.dart';

// ---- Groupes ----
import 'package:yolo/groupe/groupe_model.dart';
import 'package:yolo/groupe/groupe_service.dart';
import 'package:yolo/groupe/home_group_card.dart';

// ---- Suggestions YOLO ----
import 'package:yolo/accueil/post/suggestions/suggestion_engine.dart';
import 'package:yolo/accueil/post/suggestions/friend_activity_card.dart';
import 'package:yolo/accueil/post/suggestions/new_users_card.dart';
import 'package:yolo/accueil/post/suggestions/recommended_activity_card.dart';
import 'package:yolo/accueil/post/suggestions/region_new_activity_card.dart';

const LinearGradient sideGradient = LinearGradient(
  colors: [Color(0xFFFFF7E0), Color(0xFFFFEBC5), Color(0xFFFFE1B2)],
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
  final GroupeService _groupeService = GroupeService();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: CustomAppBar(
          title: "YOLO",
          onPublish: () async {
            final choice = await showModalPostSelector(context);

            if (choice == "post") {
              await Navigator.pushNamed(context, "/create_post");
            } else if (choice == "poll") {
              await Navigator.pushNamed(context, "/create_poll");
            } else if (choice == "activite") {
              await Navigator.pushNamed(context, "/activites");
            }
          },
        ),

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

        body: isMobile
            ? _buildFeed()
            : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(gradient: sideGradient),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _buildFeed(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(gradient: sideGradient),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FEED STREAM
  // ------------------------------------------------------------
  Widget _buildFeed() {
    return StreamBuilder(
      stream: _mergedStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final feed = snap.data as List<dynamic>;

        if (feed.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: Text(
                "Aucun contenu pour l’instant.\nPublie quelque chose 😊",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          itemCount: feed.length,
          itemBuilder: (context, i) {
            final item = feed[i];

            // Suggestions / Groupes
            if (item is Widget) return item;

            if (item is Activite) return _buildActiviteCard(item);

            if (item is Post) return _buildPostCard(item);

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // MERGED STREAM (POSTS + ACTIVITÉS + GROUPES + SUGGESTIONS)
  // ------------------------------------------------------------
  Stream<List<dynamic>> _mergedStream() {
    final activitesStream = _activiteService.streamActivites();
    final postsStream = _postService.streamFeed();
    final groupesStream = _groupeService.streamGroupes();

    return Rx.combineLatest3(activitesStream, postsStream, groupesStream, (
      List<Activite> activites,
      List<Post> posts,
      List<GroupeModel> groupes,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ACTIVITÉS à venir
      final filteredActivites = activites.where((act) {
        final d = DateTime(act.date.year, act.date.month, act.date.day);
        return d == today || d.isAfter(today);
      }).toList();

      // SUGGESTIONS YOLO
      final suggestions = await SuggestionEngine.generate(
        activities: filteredActivites,
      );

      // GROUPES → widgets
      final groupWidgets = groupes.map((g) => HomeGroupCard(group: g)).toList();

      // COMBINE TOUT
      final merged = [
        ...suggestions,
        ...groupWidgets,
        ...filteredActivites,
        ...posts,
      ];

      // TRI (posts + activités) par date
      merged.sort((x, y) {
        if (x is Widget && y is! Widget) return -1;
        if (y is Widget && x is! Widget) return 1;
        if (x is Widget && y is Widget) return 0;

        final dx = (x is Activite) ? x.date : (x as Post).date;
        final dy = (y is Activite) ? y.date : (y as Post).date;

        return dy.compareTo(dx);
      });

      return merged;
    }).asyncMap((event) async => await event);
  }

  // ------------------------------------------------------------
  // ACTIVITÉ CARD
  // ------------------------------------------------------------
  Widget _buildActiviteCard(Activite a) {
    final info = CategorieData.categories[a.categorie];
    final String emoji = info?["emoji"] ?? "✨";
    final Color catColor = info?["color"] ?? Colors.deepPurple;

    final String dayLabel = _dayLabel(a.date);
    final String hour =
        "${a.date.hour.toString().padLeft(2, '0')}h${a.date.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () => openActiviteFicheModal(context, a.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: a.photoUrl.isNotEmpty
                    ? Image.network(StorageHelper.convert(a.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : Container(color: catColor),
              ),

              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(0, 0, 0, 0.8),
                        Color.fromRGBO(0, 0, 0, 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "$emoji ${a.categorie}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.white, size: 16),
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
                        const Icon(
                          Icons.access_time_filled,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hour,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
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

  // ------------------------------------------------------------
  // POST / POLL
  // ------------------------------------------------------------
  Widget _buildPostCard(Post p) {
    if (p.isPoll == true) return PollCard(post: p);
    return PostCard(post: p);
  }

  // ------------------------------------------------------------
  // DATE LABEL
  // ------------------------------------------------------------
  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return "Aujourd’hui";
    if (diff == 1) return "Demain";

    const jours = [
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche",
    ];

    if (diff >= 2 && diff <= 6) return jours[target.weekday - 1];

    return DateFormat("dd MMM", "fr_FR").format(d);
  }
}
