// lib/event/event_detail_page.dart

import 'package:flutter/material.dart';
import 'event_model.dart';
import '../widgets/helpers/storage_helper.dart';
import '../activite/activite_creation_page.dart'; // <-- IMPORTANT : ajoute ton vrai chemin ici

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  Future<void> checkFavorite() async {
    final favs = await StorageHelper.getFavoris();
    setState(() {
      isFavorite = favs.any((e) => e.id == widget.event.id);
    });
  }

  Future<void> toggleFavorite() async {
    if (isFavorite) {
      await StorageHelper.removeFavori(widget.event);
    } else {
      await StorageHelper.addFavori(widget.event);
    }
    setState(() => isFavorite = !isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail de l’événement"),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: toggleFavorite,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────
            // IMAGE PRINCIPALE
            // ─────────────────────────────────────────────
            if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(e.imageUrl!, fit: BoxFit.cover),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.event, size: 48),
              ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────────
            // TITRE
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                e.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ─────────────────────────────────────────────
            // VILLE
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.place, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      e.address?.isNotEmpty == true
                          ? e.address!
                          : (e.city ?? "Lieu non précisé"),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ─────────────────────────────────────────────
            // DATES
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${_formatDate(e.startDate)} - ${_formatDate(e.endDate)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────────
            // DESCRIPTION
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                e.description ?? "Aucune description fournie.",
                style: const TextStyle(fontSize: 15),
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────
            // BOUTONS D'ACTION
            // ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // BOUTON PRINCIPAL : CRÉER UNE ACTIVITÉ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiviteCreationPage(
                              preTitle: e.title,
                              preDate: e.startDate,
                              preAdresse: e.address,
                              preImage: e.imageUrl,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Créer une activité pour y aller",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BOUTON : LIEN EXTERNE
                  if (e.externalUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO : ouvrir WebView ou navigateur
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("Voir plus"),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // SIMPLE DATE FORMATTER
  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')} "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }
}
