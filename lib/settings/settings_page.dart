// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Project imports:
import 'package:yolo/profil/centre_interet_page.dart';
import 'contact_page.dart';
import 'mentions_legales_page.dart';
import 'mes_amis_page.dart';
import 'mon_agenda_page.dart';
import 'politique_confidentialite_page.dart';
import 'package:yolo/connexions/login_page.dart';
import 'package:yolo/profil/profil.dart';
import 'package:yolo/Notifications/notifications_parametre_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settings = [
      {
        'icon': Icons.person,
        'title': 'Mon profil',
        'page': ProfilePage(),
      },
      {
        'icon': Icons.event,
        'title': 'Mon agenda',
        'page': MonAgendaPage(),
      },
      {
        'icon': Icons.favorite,
        'title': 'Centres d’intérêt',
        'page': CentreInteretPage(),
      },
      {
        'icon': Icons.people,
        'title': 'Mes amis',
        'page': MesAmisPage(
          profileUid: FirebaseAuth.instance.currentUser!.uid,
        ),
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications paramètres',
        'page': const NotificationSettingsPage(),
      },
      {
        'icon': Icons.contact_mail,
        'title': 'Contact',
        'page': ContactPage(),
      },
      {
        'icon': Icons.article,
        'title': 'Mentions légales',
        'page': MentionsLegalesPage(),
      },
      {
        'icon': Icons.privacy_tip,
        'title': 'Politique de confidentialité',
        'page': PolitiqueConfidentialitePage(),
      },
      {
        'icon': Icons.delete_forever,
        'title': 'Supprimer mon compte',
        'isDelete': true,
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 Bouton retour
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔸 Titre principal
                const Text(
                  "Paramètres",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 30),

                // 📋 Liste des réglages
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...settings.map((item) {
                          final bool isDelete = item['isDelete'] == true;

                          return GestureDetector(
                            onTap: () {
                              if (isDelete) {
                                _showDeleteDialog(context);
                              } else {
                                final page = item['page'];
                                if (page != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => page),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        item['icon'],
                                        color: const Color(0xFFFF7043),
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        item['title'],
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 40),

                        // 🔘 Déconnexion Firebase
                        GestureDetector(
                          onTap: () async {
                            try {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erreur de déconnexion : $e"),
                                ),
                              );
                            }
                          },
                          child: Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9C27B0),
                                    Color(0xFFFF7043),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Se déconnecter",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // 🔴 Suppression du compte Firebase + Firestore
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Supprimer mon compte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Souhaitez-vous vraiment supprimer votre compte ? Cette action est irréversible.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete();
                  await user.delete();
                }

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compte supprimé avec succès 🧹'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur lors de la suppression : $e"),
                  ),
                );
              }
            },
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }
}
