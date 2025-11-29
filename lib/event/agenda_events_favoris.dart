// 📁 event/event_action_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../event/event_model.dart';
import '../widgets/custom_button.dart';
import '../activite/activite_creation_page.dart';
import '../settings/mes_amis_page.dart';
import '../accueil/post/post/create_post.dart';

class EventActionModal extends StatelessWidget {
  final ExternalEvent event;

  const EventActionModal({super.key, required this.event});

  Future<void> _addToFavorites(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favoris_events')
        .doc(event.id);
    await ref.set({'added_at': FieldValue.serverTimestamp()});
    Navigator.pop(context);
  }

  void _shareEvent(BuildContext context) {
    final url = event.externalUrl.isNotEmpty
        ? event.externalUrl
        : 'https://yolo.app/e/${event.id}';
    Share.share("Viens avec moi à : ${event.title}\n$url");
  }

  void _createActivity(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ActiviteCreationPage(
          prefillTitle: event.title,
          prefillAddress: event.address,
          prefillCity: event.city,
          prefillStart: event.startDate,
          prefillEnd: event.endDate,
          externalEventId: event.id,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          );
        },
      ),
    );
  }

  void _inviteFriend(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MesAmisPage(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  void _postQuiVeutVenir(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CreatePost(
          prefillText: "Qui veut venir à ${event.title} ?",
          linkedEventId: event.id,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(anim),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
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
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "📍 ${event.address} - ${event.city}",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      "🕒 ${event.startDate} → ${event.endDate}",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: "Ajouter dans mes favoris",
                      onPressed: () => _addToFavorites(context),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Créer une activité avec cet événement",
                      onPressed: () => _createActivity(context),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Inviter un ami",
                      onPressed: () => _inviteFriend(context),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Qui veut venir ?",
                      onPressed: () => _postQuiVeutVenir(context),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Partager à l’extérieur",
                      onPressed: () => _shareEvent(context),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () => _shareEvent(context),
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
