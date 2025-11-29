import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yolo/accueil/post/post/post_preview_page.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController titre = TextEditingController();
  final TextEditingController texte = TextEditingController();

  final List<XFile> photos = [];

  String? username;
  String? userPhoto;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final d = snap.data() ?? {};

    setState(() {
      username = d["username"] ?? d["firstName"] ?? "Utilisateur";
      userPhoto = d["photoUrl"]; // 🔥 champ correct
    });
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() => photos.addAll(picked));
    }
  }

  void removeImage(int index) {
    setState(() => photos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFFBEB),
            Color(0xFFFFF5EE),
            Color(0xFFEFF6FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          title: const Text("Créer une publication"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -------------------------------------------------------------
              // USER HEADER
              // -------------------------------------------------------------
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        (userPhoto != null && userPhoto!.isNotEmpty)
                            ? NetworkImage(userPhoto!)
                            : null,
                    child: (userPhoto == null || userPhoto!.isEmpty)
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    username ?? "Utilisateur",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // -------------------------------------------------------------
              // TITRE
              // -------------------------------------------------------------
              TextField(
                controller: titre,
                decoration: const InputDecoration(
                  labelText: "Titre",
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // TEXTE
              // -------------------------------------------------------------
              TextField(
                controller: texte,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Texte",
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // AJOUT IMAGES
              // -------------------------------------------------------------
              GestureDetector(
                onTap: pickImages,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 6),
                        Text("Ajouter des images",
                            style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // APERÇU DES IMAGES
              // -------------------------------------------------------------
              if (photos.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(photos.length, (index) {
                    final img = photos[index];

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.network(
                                  img.path,
                                  height: 130,
                                  width: 130,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(img.path),
                                  height: 130,
                                  width: 130,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

              const SizedBox(height: 40),

              // -------------------------------------------------------------
              // BOUTON APERÇU
              // -------------------------------------------------------------
              GestureDetector(
                onTap: () async {
                  final published = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      barrierDismissible: true,
                      pageBuilder: (_, __, ___) => PostPreviewPage(
                        titre: titre.text,
                        texte: texte.text,
                        photos: photos,
                      ),
                    ),
                  );

                  if (published == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: Container(
                  height: 54,
                  width: 260,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFA855F7),
                        Color(0xFFF97316),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      "Aperçu",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
