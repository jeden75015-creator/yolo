import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late final DocumentReference configRef;

  @override
  void initState() {
    super.initState();
    configRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notificationSettings")
        .doc("config");

    // 🔥 IMPORTANT : on crée les valeurs par défaut si document inexistant
    _ensureDefaults();
  }

  // -------------------------------------------------------------
  // 🔥 Créer le document Firestore si il n'existe pas
  // -------------------------------------------------------------
  Future<void> _ensureDefaults() async {
    final snap = await configRef.get();

    if (!snap.exists) {
      await configRef.set({
        "general": true,
        "likes": true,
        "comments": true,
        "messages": true,
        "activityInvites": true,
        "newFriends": true,
        "newUsers": true,
        "suggestions": true,
        "appUpdates": true,
      });
    }
  }

  // -------------------------------------------------------------
  // 🔥 Mise à jour d'un champ Firestore
  // -------------------------------------------------------------
  Future<void> _update(String field, bool value) async {
    await configRef.set({field: value}, SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  // 🔥 UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: StreamBuilder<DocumentSnapshot>(
          stream: configRef.snapshots(),
          builder: (context, snap) {
            final data =
                snap.data?.data() as Map<String, dynamic>? ?? {};

            final general = data["general"] ?? true;
            bool val(String key) => data[key] ?? true;

            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Paramètres des notifications",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 3, 19, 80),
                      fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ---------------------------------------------------------
                // GENERAL
                // ---------------------------------------------------------
                _switch(
                  icon: Icons.notifications_active,
                  title: "Notifications générales",
                  subtitle: "Active/désactive toutes les notifications",
                  value: general,
                  onChanged: (v) => _update("general", v),
                ),

                const Divider(),

                // Si tout est désactivé → message d’avertissement
                if (!general)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Toutes les notifications sont désactivées.",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // ---------------------------------------------------------
                // OPTIONS DÉTAILLÉES
                // ---------------------------------------------------------
                if (general) ...[
                  _switch(
                    icon: Icons.favorite,
                    title: "Likes",
                    subtitle: "Quand on aime vos posts",
                    value: val("likes"),
                    onChanged: (v) => _update("likes", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.comment,
                    title: "Commentaires",
                    subtitle: "Nouveaux commentaires reçus",
                    value: val("comments"),
                    onChanged: (v) => _update("comments", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.chat,
                    title: "Messages privés",
                    subtitle: "Nouveaux messages dans vos chats",
                    value: val("messages"),
                    onChanged: (v) => _update("messages", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.event_available,
                    title: "Activités",
                    subtitle: "Invitations / messages d’activités",
                    value: val("activityInvites"),
                    onChanged: (v) => _update("activityInvites", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.group_add,
                    title: "Nouveaux amis",
                    subtitle: "Quand quelqu’un rejoint votre réseau",
                    value: val("newFriends"),
                    onChanged: (v) => _update("newFriends", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.person_add,
                    title: "Nouveaux utilisateurs",
                    subtitle: "Nouveaux membres YOLO près de vous",
                    value: val("newUsers"),
                    onChanged: (v) => _update("newUsers", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.star,
                    title: "Suggestions",
                    subtitle: "Contenus recommandés",
                    value: val("suggestions"),
                    onChanged: (v) => _update("suggestions", v),
                  ),
                  const Divider(),

                  _switch(
                    icon: Icons.system_update,
                    title: "Mises à jour YOLO",
                    subtitle: "News / updates système",
                    value: val("appUpdates"),
                    onChanged: (v) => _update("appUpdates", v),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔥 SWITCH ELEMENT
  // -------------------------------------------------------------
  Widget _switch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color.fromARGB(255, 250, 175, 1),
      activeTrackColor: const Color.fromARGB(255, 252, 198, 61).withOpacity(0.3),
      title: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 13, 16, 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(subtitle),
    );
  }
}
