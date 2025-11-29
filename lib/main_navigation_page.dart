import 'package:flutter/material.dart';

// 🔹 Tes pages principales
import 'package:yolo/accueil/home_page.dart';
import 'package:yolo/profil/reseau_page.dart';
import 'package:yolo/chats/messagerie_page.dart';
import 'package:yolo/activite/activite_liste_page.dart';
import 'package:yolo/event/event_page.dart';
import 'package:yolo/widgets/custom_bottom_navbar.dart';


class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  // ignore: unused_field
  int _previousIndex = 0;

  // 📄 Liste de toutes les pages
  final List<Widget> _pages = [
    HomePage(), // 🏠 Accueil
    const ReseauPage(), // 👥 Réseau
    const MessageriePage(), // 💬 Chat
    const ActiviteListePage(), // 🍹 Sortie
    const EventPage(), // 📅 Event
  ];

  // 🔁 Quand on clique sur un onglet
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),

      // 🌈 Animation fluide entre les pages
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_selectedIndex],
      ),

      // 🧭 Barre de navigation
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
