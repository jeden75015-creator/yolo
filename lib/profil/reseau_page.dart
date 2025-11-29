import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:yolo/accueil/home_page.dart';
import 'profil.dart';
import 'package:yolo/widgets/regions.dart';
import 'package:yolo/widgets/custom_bottom_navbar.dart';

class ReseauPage extends StatefulWidget {
  const ReseauPage({super.key});

  @override
  State<ReseauPage> createState() => _ReseauPageState();
}

class _ReseauPageState extends State<ReseauPage> {
  final user = FirebaseAuth.instance.currentUser;

  String _searchName = '';
  bool _showFilters = false;
  bool _defaultRegionFilter = true;
  String? _userRegion;

  List<String> _selectedRegions = [];
  String? _selectedOrientation;
  RangeValues _ageRange = const RangeValues(18, 70);

  // 🔥 AJOUT GENRE
  String? _selectedGender;

  final List<String> orientations = const [
    'Hétérosexuel(le)',
    'Homosexuel(le)',
    'Bisexuel(le)',
    'Pansexuel(le)',
    'Asexuel(le)',
    'Autre / Préfère ne pas dire',
  ];

  // 🔥 AJOUT LISTE GENRES
  final List<String> genders = const [
    "Homme",
    "Femme",
    "Je préfère ne pas dire",
    "Tous",
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRegion();
  }

  Future<void> _fetchCurrentUserRegion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _userRegion = (doc.data()?['region'] ?? '').toString();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la région : $e');
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedRegions = [];
      _selectedOrientation = null;
      _selectedGender = null; // 🔥 RESET GENRE
      _ageRange = const RangeValues(18, 70);
      _showFilters = false;
      _defaultRegionFilter = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 200
        ? 2
        : (screenWidth < 500 ? 3 : 5);

    return Scaffold(
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, "/home");
          if (i == 1) return;
          if (i == 2) Navigator.pushReplacementNamed(context, "/chat");
          if (i == 3) Navigator.pushReplacementNamed(context, "/activites");
          if (i == 4) Navigator.pushReplacementNamed(context, "/events");
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFFF1F2), Color(0xFFEEF2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
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
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => HomePage()),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Réseau",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchName = value.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Rechercher un prénom...",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                          _defaultRegionFilter = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.filter_alt, color: Colors.white),
                      label: const Text(
                        "Filtre",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (_defaultRegionFilter && _userRegion != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "🔸 Profils dans ta région : $_userRegion",
                    style: const TextStyle(
                      color: Color(0xFF003366),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // ----------------------------
              // 🔥 BLOC FILTRES AVEC GENRE
              // ----------------------------
              if (_showFilters)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Orientation sexuelle",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedOrientation,
                        decoration: const InputDecoration(filled: true),
                        hint: const Text("Choisir une orientation"),
                        items: orientations
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedOrientation = val),
                      ),

                      const SizedBox(height: 12),

                      // 🔥 AJOUT DU FILTRE GENRE
                      const Text(
                        "Genre",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(filled: true),
                        hint: const Text("Homme / Femme / NSPP/ Tous"),
                        items: genders
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedGender = val),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Tranche d'âge",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RangeSlider(
                        activeColor: const Color(0xFFF97316),
                        values: _ageRange,
                        min: 18,
                        max: 80,
                        divisions: 62,
                        labels: RangeLabels(
                          "${_ageRange.start.round()} ans",
                          "${_ageRange.end.round()} ans",
                        ),
                        onChanged: (values) =>
                            setState(() => _ageRange = values),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Région",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 6,
                        children: regionsFrancaises.map((r) {
                          final selected = _selectedRegions.contains(r);
                          return FilterChip(
                            label: Text(r),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedRegions.add(r);
                                } else {
                                  _selectedRegions.remove(r);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFFF97316),
                          ),
                          label: const Text(
                            "Réinitialiser",
                            style: TextStyle(color: Color(0xFFF97316)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ----------------------------
              // 🔥 LISTE DES PROFILS
              // ----------------------------
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Erreur Firestore : ${snapshot.error}"),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("⚠️ Aucun utilisateur trouvé"),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    final filtered = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      if (doc.id == user!.uid) return false;

                      final name = (data['firstName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final region = (data['region'] ?? '')
                          .toString()
                          .toLowerCase();
                      final orientation = (data['orientation'] ?? '')
                          .toString()
                          .toLowerCase();
                      final gender = (data['gender'] ?? '')
                          .toString()
                          .toLowerCase(); // 🔥

                      final birthDate = (data['birthDate'] ?? '')
                          .toString()
                          .trim();

                      int? age;
                      if (birthDate.contains('/')) {
                        final parts = birthDate.split('/');
                        if (parts.length == 3) {
                          final year = int.tryParse(parts[2]);
                          if (year != null) {
                            age = DateTime.now().year - year;
                          }
                        }
                      }

                      final matchName =
                          _searchName.isEmpty || name.contains(_searchName);

                      final matchOrientation =
                          _selectedOrientation == null ||
                          orientation ==
                              _selectedOrientation!.toLowerCase().trim();

                      // 🔥 MATCH GENRE
                      final matchGender =
                          _selectedGender == null ||
                          gender == _selectedGender!.toLowerCase().trim();

                      final matchRegion =
                          _selectedRegions.isEmpty ||
                          _selectedRegions.any(
                            (r) => region.contains(r.toLowerCase()),
                          );

                      final matchAge =
                          age == null ||
                          (age >= _ageRange.start && age <= _ageRange.end);

                      if (_defaultRegionFilter && _userRegion != null) {
                        if (!region.contains(_userRegion!.toLowerCase())) {
                          return false;
                        }
                      }

                      return matchName &&
                          matchOrientation &&
                          matchRegion &&
                          matchAge &&
                          matchGender; // 🔥 ajouté
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text("Aucun profil correspondant 😅"),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final photoUrl = data['photoUrl'] ?? '';
                        final name = data['firstName'] ?? 'Utilisateur';
                        final city = data['city'] ?? '';
                        final region = data['region'] ?? '';
                        final birthDate = (data['birthDate'] ?? '')
                            .toString()
                            .trim();

                        int? age;
                        if (birthDate.contains('/')) {
                          final parts = birthDate.split('/');
                          if (parts.length == 3) {
                            final year = int.tryParse(parts[2]);
                            if (year != null) {
                              age = DateTime.now().year - year;
                            }
                          }
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = constraints.maxWidth;
                            double scale = cardWidth / 200.0;
                            if (scale < 0.7) scale = 0.7;
                            if (scale > 1.0) scale = 1.0;

                            final double nameFontSize = 16 * scale;
                            final double cityFontSize = 13 * scale;
                            final double padding = 8 * scale;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePage(userId: doc.id),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16 * scale),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    photoUrl.isNotEmpty
                                        ? Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const ColoredBox(
                                                  color: Colors.grey,
                                                ),
                                          )
                                        : const ColoredBox(color: Colors.grey),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(padding),
                                        color: Colors.black.withOpacity(0.6),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$name${age != null ? ', $age ans' : ''}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: nameFontSize,
                                              ),
                                            ),
                                            Text(
                                              "$city${region.isNotEmpty ? ', $region' : ''}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: cityFontSize,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
