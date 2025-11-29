import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:yolo/profil/profil.dart';

class MesAmisPage extends StatefulWidget {
  final String profileUid;

  const MesAmisPage({super.key, required this.profileUid});

  @override
  State<MesAmisPage> createState() => _MesAmisPageState();
}

class _MesAmisPageState extends State<MesAmisPage>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;

  late final bool _isMe;
  String _profileName = "";
  String _search = '';
  int _tabIndex = 0;

  late AnimationController _controller;
  late Animation<double> _slider;

  final Map<String, int> _mutualCache = {};

  @override
  void initState() {
    super.initState();

    _isMe = widget.profileUid == currentUser!.uid;

    _loadUserName();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slider = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  Future<void> _loadUserName() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.profileUid)
        .get();

    if (snap.exists) {
      setState(() {
        _profileName = (snap["firstName"] ?? "").toString().toUpperCase();
      });
    }
  }

  Stream<QuerySnapshot> _followingStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUid)
        .collection('following')
        .snapshots();
  }

  Stream<QuerySnapshot> _followersStream() {
    if (!_isMe) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUid)
        .collection('followers')
        .snapshots();
  }

  Future<int> _countFollowing() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUid)
        .collection('following')
        .get();
    return snap.docs.length;
  }

  Future<int> _countFollowers() async {
    if (!_isMe) return 0;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUid)
        .collection('followers')
        .get();
    return snap.docs.length;
  }

  Future<void> _removeFollowing(String targetUid) async {
    if (!_isMe) return;
    final uid = currentUser!.uid;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid)
        .delete();

    FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid)
        .delete();
  }

  Future<int> _countMutualFriends(String otherUid) async {
    if (!_isMe) return 0;

    if (_mutualCache.containsKey(otherUid)) {
      return _mutualCache[otherUid]!;
    }

    final uid = currentUser!.uid;

    final mySnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();

    final hisSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .collection('following')
        .get();

    final mySet = mySnap.docs.map((e) => e.id).toSet();
    final hisSet = hisSnap.docs.map((e) => e.id).toSet();

    final mutual = mySet.intersection(hisSet).length;
    _mutualCache[otherUid] = mutual;

    return mutual;
  }

  void _changeTab(int index) {
    if (!_isMe && index == 1) return;

    setState(() => _tabIndex = index);

    _slider = Tween<double>(
      begin: _slider.value,
      end: index == 0 ? 0 : 1,
    ).animate(_controller);

    _controller.forward(from: 0);
  }

  Widget _profileCard(String uid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final name = (data['firstName'] ?? '').toString().toUpperCase();
        final photo = data['photoUrl'] ?? '';
        final city = data['city'] ?? '';
        final region = data['region'] ?? '';

        if (_search.isNotEmpty &&
            !name.toLowerCase().contains(_search.toLowerCase())) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<int>(
          future: _countMutualFriends(uid),
          builder: (_, mutualSnap) {
            final mutual = mutualSnap.data ?? 0;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(userId: uid)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo.isNotEmpty
                        ? Image.network(photo, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade400),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.black.withOpacity(0.55),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              city.isNotEmpty ? "$city, $region" : region,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_tabIndex == 0 && _isMe)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeFollowing(uid),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, color: Colors.red),
                          ),
                        ),
                      ),

                    if (_isMe && mutual > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                            ),
                          ),
                          child: Text(
                            mutual == 1 ? "1 mutuel" : "$mutual mutuels",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _tabIndex == 0 ? _followingStream() : _followersStream();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),

      // ❌ NAVBAR SUPPRIMÉE

      body: SafeArea(
        child: Column(
          children: [
            // HEADER ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    _isMe ? "Mes amis" : "Amis de $_profileName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),

                  // BOUTON CLOSE EN BULLE BLEUE
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // COMPTEURS ------------------------------------------------------
            FutureBuilder<List<int>>(
              future: Future.wait([
                _countFollowing(),
                _countFollowers(),
              ]),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox(height: 20);

                final following = snap.data![0];
                final followers = snap.data![1];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _isMe
                        ? "$following following • $followers followers"
                        : "$following following",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),

            // SEARCH ---------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ONGLET ---------------------------------------------------------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _slider,
                    builder: (_, __) => Positioned(
                      left: _slider.value *
                          ((MediaQuery.of(context).size.width - 32) /
                              (_isMe ? 2 : 1)),
                      top: 0,
                      bottom: 0,
                      width: (MediaQuery.of(context).size.width - 32) /
                          (_isMe ? 2 : 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _changeTab(0),
                          child: Center(
                            child: Text(
                              "Following",
                              style: TextStyle(
                                color: _tabIndex == 0
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_isMe)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _changeTab(1),
                            child: Center(
                              child: Text(
                                "Followers",
                                style: TextStyle(
                                  color: _tabIndex == 1
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // LISTE ----------------------------------------------------------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        _isMe
                            ? (_tabIndex == 0
                                ? "Tu ne suis encore personne 👀"
                                : "Personne ne te suit… 😢")
                            : "Aucun suivi pour cet utilisateur",
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (_, i) => _profileCard(docs[i].id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
