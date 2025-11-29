import 'package:flutter/material.dart';
import 'notification_badge_stream.dart';
import 'notification_badge.dart';
import 'package:yolo/Notifications/notification_page.dart';
import 'package:yolo/settings/settings_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onPublish;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,

      // 🔥 Dégradé jaune-orange standard
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

      // 🔥 BOUTON PARAMÈTRES (gauche)
      leading: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
      ),

      // 🔥 Titre
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // 🔥 Actions
      actions: [
        // BOUTON PUBLIER BLEU ✔
        GestureDetector(
          onTap: onPublish,
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

        // 🔔 Notifications
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 28,
                  color: Colors.white,
                ),
                StreamBuilder<int>(
                  stream: NotificationBadgeStream.unreadCount,
                  builder: (_, snap) {
                    final count = snap.data ?? 0;
                    return NotificationBadge(count: count);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
