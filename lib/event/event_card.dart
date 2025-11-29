import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool isFav;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenDetails;

  const EventCard({
    super.key,
    required this.event,
    required this.isFav,
    required this.onToggleFavorite,
    required this.onOpenDetails,
    
  });

  @override
  Widget build(BuildContext context) {
    // Sécurise la date si jamais elle est nulle ou mal formée
    String dateText;
    try {
      dateText = DateFormat(
        "EEE dd MMM • HH'h'mm",
        "fr_FR",
      ).format(event.startDate);
    } catch (_) {
      dateText = "Date inconnue";
    }

    return InkWell(
      onTap: onOpenDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            // ─────────────────────────────────────────────
            // IMAGE
            // ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (event.imageUrl ?? "").isNotEmpty
                  ? Image.network(
                      event.imageUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFA855F7)],
                        ),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
            ),

            const SizedBox(width: 10),

            // ─────────────────────────────────────────────
            // TEXTE (titre, date, adresse, bouton favori)
            // ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITRE + FAVORI
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          isFav ? Icons.bookmark : Icons.bookmark_border,
                          color: isFav ? Colors.orange : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // DATE
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // ADRESSE (si dispo)
                  if ((event.address ?? "").isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
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
    );
  }
}
