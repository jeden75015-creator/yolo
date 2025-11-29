import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:yolo/activite/activite_creation_page.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../activite/activite_model.dart';
import '../activite/activite_service.dart';
import '../activite/activite_fiche_page.dart';
import '../activite/categorie_data.dart';
import 'package:yolo/activite/modal_helpers.dart';

class MonAgendaPage extends StatefulWidget {
  const MonAgendaPage({super.key});

  @override
  State<MonAgendaPage> createState() => _MonAgendaPageState();
}

class _MonAgendaPageState extends State<MonAgendaPage> {
  final ActiviteService _activiteService = ActiviteService();

  bool _loading = true;

  // Removed unused field: List<Activite> _userActivities = [];
  List<Activite> _upcoming = [];

  int _sortiesTotal = 0;
  int _sortiesAVenir = 0;
  int _sortiesPassees = 0;
  int _sortiesAujourdhui = 0;
  int _sortiesCeMoisCi = 0;
  String? _categoriePreferee;

  @override
  void initState() {
    super.initState();
    _loadAgendaData();
  }

  Future<void> _loadAgendaData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final uid = user.uid;
      final allActivites = await _activiteService.getActivites();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final userActs =
          allActivites.where((a) => a.participants.contains(uid)).toList();

      // _userActivities = userActs; // Removed unused assignment

      int total = userActs.length;
      int aVenir = 0;
      int passees = 0;
      int ajd = 0;
      int ceMoisCi = 0;

      final Map<String, int> catCounter = {};

      for (final a in userActs) {
        final dateOnly = DateTime(a.date.year, a.date.month, a.date.day);

        if (dateOnly.isBefore(today)) {
          passees++;
        } else {
          aVenir++;
        }

        if (dateOnly == today) {
          ajd++;
        }

        if (a.date.year == now.year && a.date.month == now.month) {
          ceMoisCi++;
        }

        catCounter[a.categorie] = (catCounter[a.categorie] ?? 0) + 1;
      }

      String? bestCat;
      int bestCount = 0;
      catCounter.forEach((cat, count) {
        if (count > bestCount) {
          bestCount = count;
          bestCat = cat;
        }
      });

      final upcoming = userActs.where((a) {
        final dateOnly = DateTime(a.date.year, a.date.month, a.date.day);
        return !dateOnly.isBefore(today);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (!mounted) return;
      setState(() {
        _sortiesTotal = total;
        _sortiesAVenir = aVenir;
        _sortiesPassees = passees;
        _sortiesAujourdhui = ajd;
        _sortiesCeMoisCi = ceMoisCi;
        _categoriePreferee = bestCat;
        _upcoming = upcoming;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement agenda : $e")),
      );
    }
  }

  String _monthAbbrev(DateTime d) {
    const months = [
      'JAN',
      'FÉV',
      'MAR',
      'AVR',
      'MAI',
      'JUI',
      'JUIL',
      'AOÛ',
      'SEP',
      'OCT',
      'NOV',
      'DÉC'
    ];
    return months[d.month - 1];
  }

  String _monthLabelLong(DateTime d) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return "${months[d.month - 1]} ${d.year}";
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  String _extractCity(String adresse, String region) {
    if (adresse.contains(',')) {
      final parts = adresse.split(',');
      final last = parts.last.trim();
      if (last.isNotEmpty) return last;
    }
    return region;
  }

  String _categoriePrefDisplay() {
    if (_categoriePreferee == null) {
      return "Aucune encore, à toi de jouer ✨";
    }

    final info = CategorieData.categories[_categoriePreferee!];
    if (info == null) {
      return _categoriePreferee!;
    }
    final emoji = info["emoji"] ?? "✨";
    final label = _categoriePreferee!;
    return "$emoji $label";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFBEB),
              Color(0xFFFFE4F1),
              Color(0xFFEFF2FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.menu,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      "✨ Mon agenda",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActiviteCreationPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "Créer",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // STATS
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _loading
                    ? const SizedBox(
                        height: 30,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF97316),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatLineItem(
                            label: "Sorties",
                            valueColor: const Color(0xFFF97316),
                            value: _sortiesTotal,
                          ),
                          _StatLineItem(
                            label: "À venir",
                            valueColor:
                                const Color.fromARGB(255, 213, 5, 102),
                            value: _sortiesAVenir,
                          ),
                          _StatLineItem(
                            label: "Passées",
                            valueColor:
                                const Color.fromARGB(221, 137, 100, 33),
                            value: _sortiesPassees,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 14),

              // CONTENU PRINCIPAL
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF97316),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _upcomingList(context, _upcoming),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 16),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: _rightPanel(
                                  monthLabel: _monthLabelLong(now),
                                  sortiesAujourdhui: _sortiesAujourdhui,
                                  sortiesCeMoisCi: _sortiesCeMoisCi,
                                  categoriePreferee: _categoriePrefDisplay(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) Navigator.pushNamed(context, '/home');
          if (i == 1) Navigator.pushNamed(context, '/reseau');
          if (i == 2) Navigator.pushNamed(context, '/chat');
          if (i == 3) Navigator.pushNamed(context, '/activites');
          if (i == 4) Navigator.pushNamed(context, '/events');
        },
      ),
    );
  }

  Widget _upcomingList(BuildContext context, List<Activite> events) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Aucune sortie à venir pour l’instant.\nPlanifie-toi quelque chose ✨",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = events[index];
        return GestureDetector(
          onTap: () => openActiviteFicheModal(context, a.id),
          child: _eventItem(a),
        );
      },
    );
  }

  Widget _eventItem(Activite a) {
    const corail = Color(0xFFFF7043);
    const violet = Color(0xFFA855F7);

    final month = _monthAbbrev(a.date);
    final day = a.date.day.toString();
    final heure = _formatTime(a.date);
    final city = _extractCity(a.adresse, a.region);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [violet, Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.titre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled,
                        size: 16, color: corail),
                    const SizedBox(width: 4),
                    Text(
                      heure,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: violet),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFBEB),
                      Color(0xFFEFF6FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  a.categorie,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: corail,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    "${a.participants.length}/${a.maxParticipants}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rightPanel({
    required String monthLabel,
    required int sortiesAujourdhui,
    required int sortiesCeMoisCi,
    required String categoriePreferee,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "✨ Mon agenda",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            monthLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sorties aujourd’hui : $sortiesAujourdhui",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 18),
          const Text(
            "✨ Ton activité",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Sorties ce mois-ci : $sortiesCeMoisCi",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Ta catégorie préférée : $categoriePreferee",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLineItem extends StatelessWidget {
  final String label;
  final Color valueColor;
  final int value;

  const _StatLineItem({
    required this.label,
    required this.valueColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
