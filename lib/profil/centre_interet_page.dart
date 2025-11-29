// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CentreInteretPage extends StatefulWidget {
  // 🆕 AJOUT : paramètres pour mode groupe
  final List<String>? selectionInitiale; // pour pré-remplir en mode groupe
  final bool isGroupMode; // true = groupe, false = utilisateur
  final int maxGroupInterests; // limite de sélection pour groupe

  const CentreInteretPage({
    super.key,
    this.selectionInitiale,
    this.isGroupMode = false,
    this.maxGroupInterests = 5,
  });

  @override
  State<CentreInteretPage> createState() => _CentreInteretPageState();
}

class _CentreInteretPageState extends State<CentreInteretPage>
    with SingleTickerProviderStateMixin {
  final Map<String, List<String>> allInterests = {
    'Sports': [
      'Football',
      'Basket-ball',
      'Tennis',
      'Running',
      'Natation',
      'Cyclisme',
      'Aviron',
      'Yoga',
      'Arts martiaux',
      'Escalade',
      'Surf',
      'Ski',
      'Fitness',
      'Danse',
      'Boxe',
      'Paddle',
      'Golf',
      'Volleyball',
      'Rugby',
    ],
    'Nouvelles technologies': [
      'Intelligence artificielle',
      'Objets connectés',
      'Impression 3D',
      'Réalité augmentée',
      'Réalité virtuelle',
      'Robotique',
      'Drones',
      'Domotique',
      'Crypto-monnaies',
      'Blockchain',
      'Applications mobiles',
      'Cybersécurité',
      'Cloud computing',
      'Startups',
      'Jeux vidéo',
    ],
    'Arts': [
      'Dessin',
      'Peinture',
      'Sculpture',
      'Photographie',
      'Vidéo / montage',
      'Cinéma',
      'Comedie club',
      'Théâtre',
      'Mode',
      'Design graphique',
      'Art urbain',
      'Écriture créative',
      'Composition musicale',
      'DJing',
    ],
    'Voyages': [
      'Découverte',
      'Road trip',
      'Camping',
      'Trekking',
      'Croisière',
      'Tourisme local',
      'Nature',
      'Voyages gastronomiques',
    ],
    'Culture': [
      'Lecture',
      'LGBTQIA+',
      'Bandes dessinées',
      'Philosophie',
      'Musées',
      'Cinéma',
      'Développement personnel',
      'Histoire',
      'Poésie',
    ],
    'Bien-être': [
      'Yoga',
      'Pilates',
      'Méditation',
      'Pleine conscience',
      'Course à pied',
      'Fitness',
      'Nutrition',
      'Massages',
      'Danse',
    ],
    'Musique': [
      'Rock',
      'Pop',
      'Jazz',
      'Classique',
      'Electro',
      'Rap',
      'Reggae',
      'R’n’B',
      'Soul',
      'Funk',
    ],
    'Langues': [
      'Français',
      'Anglais',
      'Espagnol',
      'Italien',
      'Allemand',
      'Arabe',
      'Chinois',
      'Japonais',
      'Coréen',
      'Créole',
    ],
  };

  final Set<String> selectedInterests = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // 👉 pour utilisateur : 15
  // 👉 pour groupe : 5
  int get maxInterests => widget.isGroupMode ? widget.maxGroupInterests : 15;

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    if (widget.isGroupMode) {
      // 🆕 Mode groupe → pas de Firestore, juste précharger
      selectedInterests.addAll(widget.selectionInitiale ?? []);
      _isLoading = false;
      _controller.forward();
    } else {
      // Mode utilisateur → comportement normal
      _loadUserInterests();
    }
  }

  // 🔥 Mode utilisateur → Firestore
  Future<void> _loadUserInterests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('interests')) {
        final raw = doc['interests'];
        if (raw is List) {
          selectedInterests.addAll(raw.map((e) => e.toString()));
        }
      }

      await _controller.forward();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de chargement : $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 Mode utilisateur → sauvegarde Firestore
  Future<void> _saveUserInterests() async {
    if (_isSaving) return;

    if (selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Choisis au moins un centre d’intérêt !"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'interests': selectedInterests.toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centres d’intérêt mis à jour ✅'),
          backgroundColor: Color(0xFFFF7043),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 🔥 Mode groupe → on renvoie juste la sélection
  void _returnGroupInterests() {
    Navigator.pop(context, selectedInterests.toList());
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        if (selectedInterests.length >= maxInterests) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Tu peux choisir jusqu’à $maxInterests centres d’intérêt maximum.",
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          return;
        }
        selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFFF1F2), Color(0xFFEEF2FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------------------------
                // 🔹 Header
                // ----------------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.isGroupMode
                            ? "Centres du groupe"
                            : "Centres d’intérêt",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${selectedInterests.length} / $maxInterests",
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.isGroupMode
                        ? "Choisis les centres d’intérêt du groupe 🎯"
                        : "Modifie ou complète tes centres d’intérêt 🎨",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------------------------------
                // 🧩 Liste des catégories
                // ----------------------------------------------------------------------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: allInterests.entries.map((entry) {
                          final category = entry.key;
                          final interests = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: interests.map((interest) {
                                  final isSelected = selectedInterests.contains(
                                    interest,
                                  );
                                  return GestureDetector(
                                    onTap: () => _toggleInterest(interest),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF97316)
                                            : Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFF97316)
                                              : Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(2, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        interest,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 15),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------------------------
                // 🔘 Bouton Enregistrer ou Valider
                // ----------------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: GestureDetector(
                    onTap: _isSaving
                        ? null
                        : widget.isGroupMode
                        ? _returnGroupInterests // 🆕
                        : _saveUserInterests,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isSaving && !widget.isGroupMode
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.isGroupMode ? "Valider" : "Enregistrer",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
