import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yolo/profil/profil.dart';

import 'groupe_model.dart';
import 'groupe_service.dart';

class MembersListPage extends StatefulWidget {
  final GroupeModel groupe;

  const MembersListPage({super.key, required this.groupe});

  @override
  State<MembersListPage> createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  final _user = FirebaseAuth.instance.currentUser!;
  final GroupeService _service = GroupeService();

  late GroupeModel _groupe;
  late bool _isAdmin;
  StreamSubscription<DocumentSnapshot>? _groupSub;

  @override
  void initState() {
    super.initState();
    _groupe = widget.groupe;
    _isAdmin = _groupe.admins.contains(_user.uid);
    _listenGroupLive();
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // -------------------------------------------------------
  // 🔥 Résolution couleur (int, hex, string)
  // -------------------------------------------------------
  Color _resolveColor(dynamic raw) {
    try {
      if (raw == null) return Colors.deepPurple;
      if (raw is int) return Color(raw);

      final v = raw.toString().trim();

      if (v.startsWith("#")) {
        return Color(int.parse(v.replaceFirst("#", "0xff")));
      }
      if (v.startsWith("0x")) {
        return Color(int.parse(v));
      }
      return Color(int.parse(v));
    } catch (_) {
      return Colors.deepPurple;
    }
  }

  // -------------------------------------------------------
  // 🔥 Écoute groupe live
  // -------------------------------------------------------
  void _listenGroupLive() {
    _groupSub = FirebaseFirestore.instance
        .collection("groupes")
        .doc(_groupe.id)
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          safeSetState(() {
            _groupe = GroupeModel.fromFirestore(snap);
            _isAdmin = _groupe.admins.contains(_user.uid);
          });
        });
  }

  // -------------------------------------------------------
  // 🔥 CALCUL ÂGE — Compatible "12/10/2005"
  // -------------------------------------------------------
  int? _computeAge(dynamic birthRaw) {
    if (birthRaw == null) return null;

    DateTime? birth;

    try {
      if (birthRaw is Timestamp) {
        birth = birthRaw.toDate();
      } else if (birthRaw is String) {
        final raw = birthRaw.trim();

        // Format JJ/MM/AAAA
        if (raw.contains("/")) {
          final p = raw.split("/");
          if (p.length == 3) {
            final d = int.tryParse(p[0]);
            final m = int.tryParse(p[1]);
            final y = int.tryParse(p[2]);
            if (d != null && m != null && y != null) {
              birth = DateTime(y, m, d);
            }
          }
        }

        // Format ISO (AAAA-MM-JJ)
        birth ??= DateTime.tryParse(raw);
      }
    } catch (_) {
      birth = null;
    }

    if (birth == null) return null;

    final now = DateTime.now();
    int age = now.year - birth.year;

    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }

    return age;
  }

  // -------------------------------------------------------
  // POPUP MEMBRE
  // -------------------------------------------------------
  void _showMemberPopup(String uid, String prenom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                prenom,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
                title: const Text("Voir le profil"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage(userId: uid)),
                  );
                },
              ),
              if (uid != _user.uid)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text("Signaler"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _service.signalerMembre(_groupe.id, uid);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Signalement envoyé")),
                    );
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------
  // 🧩 TUile visuelle d’un membre
  // -------------------------------------------------------
  Widget _buildMemberTile(String uid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snap.data!.data() as Map<String, dynamic>;

        final prenom = data["firstName"] ?? "Utilisateur";
        final photoUrl = data["photoUrl"] ?? "";
        final age = _computeAge(data["birthDate"]);
        final ageLabel = age != null ? age.toString() : "—";

        return GestureDetector(
          onTap: () => _showMemberPopup(uid, prenom),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black12.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // ---------- PHOTO ----------
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: photoUrl.isNotEmpty
                        ? Image.network(photoUrl, fit: BoxFit.cover)
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                ),

                // ---------- TEXTE ----------
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "$ageLabel • $prenom",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------
  // BUILD PAGE
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final ordered = <String>[
      ..._groupe.admins,
      ..._groupe.membres.where((m) => !_groupe.admins.contains(m)),
      ..._groupe.bannis,
    ];

    final unique = ordered.toSet().toList();

    int crossAxisCount = (MediaQuery.of(context).size.width / 130).floor();
    if (crossAxisCount < 3) crossAxisCount = 3;
    if (crossAxisCount > 10) crossAxisCount = 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Membres du groupe"),
        backgroundColor: _resolveColor(_groupe.couleur),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: "Vous êtes admin",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fonctionnalités admin à venir !")),
                );
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F4EB),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          itemCount: unique.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (_, i) => _buildMemberTile(unique[i]),
        ),
      ),
    );
  }
}
