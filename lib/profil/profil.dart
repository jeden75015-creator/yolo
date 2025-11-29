import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:yolo/connexions/login_page.dart';
import 'package:yolo/chats/chat_page.dart';
import 'edit_profil_page.dart';
import 'package:yolo/widgets/custom_bottom_navbar.dart';
import 'package:yolo/settings/mes_amis_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  bool _isMe = true;
  bool _isFollowing = false;

  String? _profileUid;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;

      final uid = widget.userId ?? current.uid;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      final isMe = uid == current.uid;

      bool isFollowing = false;

      if (!isMe) {
        final followDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .collection('following')
            .doc(uid)
            .get();

        isFollowing = followDoc.exists;
      }

      setState(() {
        _profileUid = uid;
        _isMe = isMe;
        _isFollowing = isFollowing;
        userData = data;
        _isLoading = false;
      });

      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur profil : $e")),
      );
    }
  }

  Future<void> toggleFollow() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null || _profileUid == null) return;

    final myUid = current.uid;
    final targetUid = _profileUid!;

    final users = FirebaseFirestore.instance.collection('users');

    final myFollowing = users.doc(myUid).collection('following').doc(targetUid);
    final targetFollowers =
        users.doc(targetUid).collection('followers').doc(myUid);

    final bool newValue = !_isFollowing;

    setState(() {
      _isFollowing = newValue;
    });

    try {
      if (newValue) {
        await myFollowing.set({'since': DateTime.now()});
        await targetFollowers.set({'since': DateTime.now()});

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': targetUid,
          'fromUserId': myUid,
          'type': 'follow',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await myFollowing.delete();
        await targetFollowers.delete();
      }

      await loadUser();
    } catch (e) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
    }
  }

  int? _calculateAge(String birthDate) {
    try {
      final parts = birthDate.split('/');
      if (parts.length != 3) return null;

      final d = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final y = int.parse(parts[2]);

      final now = DateTime.now();
      int age = now.year - y;
      if (now.month < m || (now.month == m && now.day < d)) age--;

      return max(age, 0);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text("Profil introuvable.")),
      );
    }

    final prenom = userData?['firstName'] ?? 'Utilisateur';
    final photoUrl = userData?['photoUrl'] ?? '';
    final bio = userData?['bio'] ?? '';
    final city = userData?['city'] ?? '';
    final region = userData?['region'] ?? '';
    final birthDate = userData?['birthDate'] ?? '';
    final age = _calculateAge(birthDate);

    final postsCount = (userData?['postsCount'] ?? 0) as int;
    final activitiesCount = (userData?['activitiesCount'] ?? 0) as int;
    final friendsCount = (userData?['friendsCount'] ?? 0) as int;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),

      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, "/home");
          if (i == 1) {}
          if (i == 2) Navigator.pushReplacementNamed(context, "/chat");
          if (i == 3) Navigator.pushReplacementNamed(context, "/activites");
          if (i == 4) Navigator.pushReplacementNamed(context, "/events");
        },
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFBEB),
              Color(0xFFFFF1F2),
              Color(0xFFEFF6FF)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 38,
                            width: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                        ),

                        if (_isMe)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilPage(),
                                ),
                              ).then((_) => loadUser());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Modifier",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 80),

                        if (_isMe)
                          GestureDetector(
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );
                              }
                            },
                            child: const Icon(Icons.logout),
                          )
                        else
                          const SizedBox(width: 26),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // CARTE PROFIL
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bande haute avec avatar et prénom
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFD54F),
                                        Color(0xFFFF7043)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundImage: photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl.isEmpty
                                            ? const Icon(Icons.person, size: 40)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prenom.toString().toUpperCase(), // MAJUSCULE
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (age != null)
                                              Text(
                                                "$age ans",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey.shade900,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (city.isNotEmpty || region.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Localisation",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 18,
                                                  color: Color(0xFF6366F1),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    "$city, $region",
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),

                                      const Text(
                                        "Bio",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        bio.isNotEmpty
                                            ? bio
                                            : "Aucune bio renseignée.",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      const Text(
                                        "Amis",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildFriendsPreview(),

                                      const SizedBox(height: 16),

                                      const Text(
                                        "Centres d'intérêt",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInterests(),

                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          if (!_isMe) _buildActionsRow(),

                          const SizedBox(height: 16),

                          _buildStatsBlock(
                            postsCount,
                            activitiesCount,
                            friendsCount,
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // AMIS (aperçu) — MAX 15 + FLÈCHE → MesAmisPage()
  // ------------------------------------------------------------------
  Future<List<String>> _loadFriendsIds() async {
    if (_profileUid == null) return [];

    final usersCol = FirebaseFirestore.instance.collection('users');

    final followersSnap =
        await usersCol.doc(_profileUid).collection('followers').get();
    final followingSnap =
        await usersCol.doc(_profileUid).collection('following').get();

    final setIds = <String>{};

    for (var d in followersSnap.docs) setIds.add(d.id);
    for (var d in followingSnap.docs) setIds.add(d.id);

    return setIds.toList();
  }

  Widget _buildFriendsPreview() {
    if (_profileUid == null) return const SizedBox.shrink();

    return FutureBuilder<List<String>>(
      future: _loadFriendsIds(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final ids = snap.data!;
        if (ids.isEmpty) {
          return const Text(
            "Aucun ami pour le moment.",
            style: TextStyle(color: Colors.black54),
          );
        }

        final limited = ids.take(15).toList();
        final hasMore = ids.length > 15;

        return SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: limited.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final friendUid = limited[i];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(friendUid)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final data = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final prenomAmi = (data['firstName'] ?? '').toString().toUpperCase();
                        final photo = data['photoUrl'] ?? '';

                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  photo.isNotEmpty ? NetworkImage(photo) : null,
                              child: photo.isEmpty
                                  ? const Icon(Icons.person, size: 18)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                prenomAmi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold, // GRAS
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // FLÈCHE → PAGE MES AMIS
              if (hasMore)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MesAmisPage(profileUid: _profileUid!),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // INTERETS
  // ------------------------------------------------------------------
  Widget _buildInterests() {
    final List interests = userData?['interests'] ?? [];

    if (interests.isEmpty) {
      return const Text(
        "Aucun centre d'intérêt renseigné.",
        style: TextStyle(color: Colors.black54),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFE4F1),
                Color(0xFFEFF6FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            interest.toString(),
            style: const TextStyle(
              color: Color.fromARGB(255, 110, 1, 46),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------------
  // ACTIONS (follow + discuter)
  // ------------------------------------------------------------------
  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: toggleFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  _isFollowing ? "Ne plus suivre" : "Suivre",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_profileUid == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    conversationId: null,
                    otherUserId: _profileUid!,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFFFB347)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Text(
                  "Discuter",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // STATS
  // ------------------------------------------------------------------
  Widget _buildStatsBlock(int posts, int activities, int friends) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Postes", posts, const Color(0xFFF97316)),
          _statItem("Activités", activities, const Color(0xFFA855F7)),
          _statItem("Amis", friends, const Color.fromARGB(221, 137, 100, 33)),
        ],
      ),
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$value",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
