// 📁 event/event_action_modal.dart
import 'package:flutter/material.dart';
import 'package:yolo/lib/event/event_model.dart';
import 'package:yolo/lib/widgets/custom_button.dart';

class EventActionModal extends StatelessWidget {
  final ExternalEvent event;

  const EventActionModal({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (event.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text("📍 ${event.address} - ${event.city}"),
                    Text("🕒 ${event.startDate} → ${event.endDate}"),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: "Ajouter dans mes favoris",
                      onPressed: () {
                        // TODO : ajouter à la liste des favoris
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Créer une activité avec cet événement",
                      onPressed: () {
                        // TODO : pré-remplir la création d'activité
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Inviter un ami",
                      onPressed: () {
                        // TODO : ouvrir la liste d’amis
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Partager à l’extérieur",
                      onPressed: () {
                        // TODO : lien de partage externe
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () {
                    // TODO : déclencher le partage externe immédiat
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
