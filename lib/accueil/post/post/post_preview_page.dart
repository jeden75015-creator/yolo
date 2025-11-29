import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../post_model.dart';
import '../post_service.dart';
import '../../../profil/user_service.dart';

class PostPreviewPage extends StatelessWidget {
  final String? titre;
  final String? texte;
  final List<XFile> photos;

  PostPreviewPage({
    super.key,
    this.titre,
    this.texte,
    required this.photos,
  });

  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.45),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // bloque la fermeture
            child: _zoomContainer(
              child: _card(context),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Animation Zoom
  // ---------------------------------------------------------------
  Widget _zoomContainer({required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (_, scale, __) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale,
            child: child,
          ),
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titre != null && titre!.isNotEmpty)
            Text(
              titre!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

          if (titre != null && titre!.isNotEmpty)
            const SizedBox(height: 10),

          if (texte != null && texte!.isNotEmpty)
            Text(
              texte!,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),

          const SizedBox(height: 16),

          if (photos.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView(
                children: photos.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: kIsWeb
                        ? Image.network(img.path, fit: BoxFit.cover)
                        : Image.file(File(img.path), fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 30),

          GestureDetector(
            onTap: () async {
              await _publishPost(context);
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFA855F7),
                    Color(0xFFF97316),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  "Publier",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 🔥 Création + Upload + Firestore
  // ---------------------------------------------------------------
  Future<void> _publishPost(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. User Data
    final user = await UserService().getUser(uid);

    // 2. Upload images
    final List<String> photoUrls = [];
    for (final xfile in photos) {
      final url = await _uploadImage(xfile);
      photoUrls.add(url);
    }

    // 3. Firestore ID du post
    final docRef = FirebaseFirestore.instance.collection("posts").doc();

    // 4. Construire Post
    final post = Post(
      id: docRef.id,
      userId: uid,
      userName: user?["username"] ?? "Utilisateur",
      userPhoto: user?["photoUrl"],

      titre: (titre?.isEmpty ?? true) ? null : titre,
      texte: (texte?.isEmpty ?? true) ? null : texte,
      photoUrls: photoUrls,

      date: DateTime.now(),
      likes: 0,
      likedByMe: false,
      commentsCount: 0,

      isPoll: false,
      question: null,
      options: [],
      voted: [],
    );

    // 5. Firestore
    await _postService.createPost(post);

    // 6. Success
    await _showSuccess(context);

    Navigator.pop(context, true);
  }

  // ---------------------------------------------------------------
  // Upload Firebase Storage
  // ---------------------------------------------------------------
  Future<String> _uploadImage(XFile file) async {
    final ref = FirebaseStorage.instance.ref(
      "posts/${DateTime.now().millisecondsSinceEpoch}_${file.name}",
    );

    if (kIsWeb) {
      await ref.putData(await file.readAsBytes());
    } else {
      await ref.putFile(File(file.path));
    }

    return await ref.getDownloadURL();
  }

  // ---------------------------------------------------------------
  // Success Animation
  // ---------------------------------------------------------------
  Future<void> _showSuccess(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) {
        return Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            builder: (_, scale, __) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 70,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 700));
    Navigator.of(context, rootNavigator: true).pop();
  }
}
