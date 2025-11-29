import 'package:flutter/material.dart';
import 'event_model.dart';
import 'event_service.dart';
import 'event_card.dart';
import 'event_map.dart';
import 'event_detail_page.dart';
import '../widgets/helpers/storage_helper.dart';

class AroundMeTab extends StatefulWidget {
  final bool showMap;

  const AroundMeTab({super.key, required this.showMap});

  @override
  State<AroundMeTab> createState() => _AroundMeTabState();
}

class _AroundMeTabState extends State<AroundMeTab>
    with SingleTickerProviderStateMixin {
  List<EventModel> events = [];
  List<EventModel> filtered = [];

  bool loading = true;
  String search = "";

  // favoris : stockés sous forme d'IDs
  List<String> favIds = [];

  // géoloc user (placeholder Paris pour l’instant)
  double? userLat;
  double? userLon;

  // Rayon dynamique
  final List<int> radiusOptions = [2, 8, 20, 50];
  int radiusKm = 8;

  // ANIMATION LISTE ↔ CARTE
  late AnimationController _anim;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    loadFavoris();
    loadNearby();
  }

  @override
  void didUpdateWidget(covariant AroundMeTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showMap != oldWidget.showMap) {
      widget.showMap ? _anim.forward() : _anim.reverse();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CHARGE LES ÉVÉNEMENTS À PROXIMITÉ (BACKEND)
  // ─────────────────────────────────────────────
  Future<void> loadNearby() async {
    try {
      setState(() => loading = true);

      // TODO: remplacer par la vraie géoloc
      const double lat = 48.8566; // Paris
      const double lon = 2.3522;

      final result = await EventService.getNearbyEvents(
        lat,
        lon,
        radiusKm: radiusKm.toDouble(),
        limit: 100,
      );

      setState(() {
        userLat = lat;
        userLon = lon;
        events = result;
        filtered = _applySearch(result, search);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // Option: afficher une snackbar
      debugPrint("Erreur loadNearby: $e");
    }
  }

  // ─────────────────────────────────────────────
  // FAVORIS
  // ─────────────────────────────────────────────
  Future<void> loadFavoris() async {
    final favs = await StorageHelper.getFavoris();
    setState(() {
      favIds = favs.map((e) => e.id).toList();
    });
  }

  void toggleFavori(EventModel e) async {
    final isFav = favIds.contains(e.id);

    if (isFav) {
      await StorageHelper.removeFavori(e);
    } else {
      await StorageHelper.addFavori(e);
    }

    await loadFavoris(); // rafraîchit aussi la carte et la liste
    setState(() {}); // force rebuild
  }

  // ─────────────────────────────────────────────
  // RECHERCHE
  // ─────────────────────────────────────────────
  void applyFilter(String value) {
    search = value;
    setState(() {
      filtered = _applySearch(events, search);
    });
  }

  List<EventModel> _applySearch(List<EventModel> source, String text) {
    if (text.isEmpty) return List<EventModel>.from(source);

    final lower = text.toLowerCase();
    return source.where((e) {
      return e.title.toLowerCase().contains(lower) ||
          (e.city ?? "").toLowerCase().contains(lower);
    }).toList();
  }

  // ─────────────────────────────────────────────
  // CHANGEMENT DE RAYON
  // ─────────────────────────────────────────────
  Future<void> changeRadius(int km) async {
    setState(() {
      radiusKm = km;
    });
    await loadNearby();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _buildList(),

        // CARTE AVEC ANIMATION
        SlideTransition(
          position: _slide,
          child: widget.showMap
              ? Container(
                  color: Colors.white,
                  child: EventMap(
                    events: filtered,
                    favEventIds: favIds,
                    userLat: userLat,
                    userLon: userLon,
                    radiusKm: radiusKm.toDouble(),
                    onToggleFavorite: toggleFavori,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // LISTE 2 PAR LIGNE
  // ─────────────────────────────────────────────
  Widget _buildList() {
    return Column(
      children: [
        // Rayon chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: radiusOptions.map((km) {
              final selected = km == radiusKm;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text("${km} km"),
                  selected: selected,
                  onSelected: (_) => changeRadius(km),
                ),
              );
            }).toList(),
          ),
        ),

        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Rechercher un événement...",
              border: OutlineInputBorder(),
            ),
            onChanged: applyFilter,
          ),
        ),

        // Grille
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .78,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final e = filtered[i];
              final isFav = favIds.contains(e.id);

              return EventCard(
                event: e,
                isFav: isFav,
                onToggleFavorite: () => toggleFavori(e),
                onOpenDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailPage(event: e),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
