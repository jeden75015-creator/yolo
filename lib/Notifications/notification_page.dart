import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'notifications_parametre_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({"read": true});
  }

  Future<void> _deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
              );
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),

          builder: (context, snap) {
            // 🔥 Sécurité chargement
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              );
            }

            // 🔥 On récupère les docs et on trie nous-même (fallback)
            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "Aucune notification 📭",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            // 🔥 TRI LOCAL SI timestamp manquant
            final sorted = docs.toList()
              ..sort((a, b) {
                final ta = (a['timestamp'] is Timestamp)
                    ? a['timestamp'] as Timestamp
                    : Timestamp(0, 0);

                final tb = (b['timestamp'] is Timestamp)
                    ? b['timestamp'] as Timestamp
                    : Timestamp(0, 0);

                return tb.compareTo(ta);
              });

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final doc = sorted[i];
                final data = doc.data() as Map<String, dynamic>;

                final title = data["title"] ?? "Notification";
                final message = data["message"] ?? "Message non disponible";
                final isRead = data["read"] ?? false;

                return Card(
                  color: isRead ? Colors.white : Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_active,
                      color: isRead ? Colors.deepPurple : Colors.deepOrange,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(message, maxLines: 2),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _deleteNotification(doc.id),
                    ),
                    onTap: () => _markAsRead(doc.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
