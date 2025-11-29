import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../post_model.dart';
import '../post_service.dart';
import '../../../profil/user_service.dart';

class PollPreviewPage extends StatelessWidget {
  final String question;
  final List<String> options;

  const PollPreviewPage({
    super.key,
    required this.question,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.45),

      body: GestureDetector(
        onTap: () => Navigator.pop(context, false),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: _zoomContainer(
              child: _card(context),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------
  Widget _zoomContainer({required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (_, scale, __) {
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: scale, child: child),
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  Widget _card(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Aperçu du sondage",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          ...options.map((o) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(o, style: const TextStyle(fontSize: 16)),
            );
          }),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _publishPoll(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFA855F7),
                          Color(0xFFF97316),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Publier",
                        style: TextStyle(
                          color: Colors.white,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 🔥 Publication Firestore réelle via PostService
  // ---------------------------------------------------------------
  Future<void> _publishPoll(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. User Data
    final user = await UserService().getUser(uid);

    // 2. Options du sondage
    final pollOptions = options
        .map((text) => PollOption(text: text, votes: 0))
        .toList();

    // 3. ID Firestore
    final postRef = FirebaseFirestore.instance.collection("posts").doc();

    // 4. Construction du Post
    final post = Post(
      id: postRef.id,
      userId: uid,
      userName: user?["username"] ?? "Utilisateur",
      userPhoto: user?["photoUrl"],

      // pas de texte / titre / images
      titre: null,
      texte: null,
      photoUrls: [],

      date: DateTime.now(),
      likes: 0,
      likedByMe: false,
      commentsCount: 0,

      isPoll: true,
      question: question,
      options: pollOptions,
      voted: [],
    );

    // 5. Envoi
    await PostService().createPoll(post);

    // 6. Animation OK
    await _showSuccessOverlay(context);

    Navigator.pop(context, true);
  }

  // ---------------------------------------------------------------
  // Overlay Validé
  // ---------------------------------------------------------------
  Future<void> _showSuccessOverlay(BuildContext context) async {
    final overlay = OverlayEntry(
      builder: (_) => Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          builder: (_, scale, __) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            );
          },
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 700));
    overlay.remove();
  }
}
