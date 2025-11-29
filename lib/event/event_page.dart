// 📁 event/event_page.dart
import 'package:flutter/material.dart';
import 'package:yolo/lib/event/autour_de_moi_page.dart';
import 'package:yolo/lib/event/agenda_events_favoris.dart';
import 'package:yolo/lib/theme/app_colors.dart';
import 'package:yolo/lib/event/discover_tab.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  int _tabIndex = 0;
  bool _vueCarte = false;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const DiscoverTab(),
      _vueCarte ? const EventMap() : const AutourDeMoiPage(),
      const AgendaEventsFavoris(),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // 🔥 NAVBAR HAUT (dégradé orange)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      // TODO: action partager globale
                    },
                  ),
                  const Text(
                    "Événements",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_tabIndex == 1)
                    GestureDetector(
                      onTap: () {
                        setState(() => _vueCarte = !_vueCarte);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _vueCarte ? "Vue Liste" : "Vue Carte",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                ],
              ),
            ),

            // 🔥 BARRE DES TABS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _tabItem("Découvrir", 0),
                  _tabItem("Autour de moi", 1),
                  _tabItem("Favoris", 2),
                ],
              ),
            ),

            // 🔥 CONTENU
            Expanded(child: tabs[_tabIndex]),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _tabIndex = index;
        _vueCarte = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.deepOrange.shade400,
                    width: 3,
                  ),
                ),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.deepOrange : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// ⚠️ Manque encore DiscoverTab, EventMap, AgendaEventsFavoris => déjà existants ou à compléter
