import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_icon_with_badge.dart';

class CustomBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool secondary;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = secondary ? Colors.white70 : Colors.white;
    final Color unselectedColor = Colors.white70;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 244, 198, 48),
            Color(0xFFF97316),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),

      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: userId)
            .where("read", isEqualTo: false)
            .snapshots(),

        builder: (context, snapshot) {
          final unread = snapshot.data?.docs.length ?? 0;

          return BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: secondary ? 0 : currentIndex,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: onTap,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: 'Réseau',
              ),

              /// 🔥 Icône avec BADGE dynamique
              BottomNavigationBarItem(
                icon: ChatIconWithBadge(unreadCount: unread),
                label: 'Chat',
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports_rounded),
                label: 'Activité',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.event_available_rounded),
                label: 'Event',
              ),
            ],
          );
        },
      ),
    );
  }
}
