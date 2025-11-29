// Dart imports:
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'auth_service.dart';

import 'interests_page.dart'; // 👉 prochaine étape après la photo

class PhotoProfilCreationPage extends StatefulWidget {
  const PhotoProfilCreationPage({super.key});

  @override
  State<PhotoProfilCreationPage> createState() =>
      _PhotoProfilCreationPageState();
}

class _PhotoProfilCreationPageState extends State<PhotoProfilCreationPage> {
  Uint8List? _webImage;
  File? _mobileImage;
  bool _isUploading = false;
  double _progress = 0;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImage = bytes;
        _mobileImage = null;
      });
    } else {
      setState(() {
        _mobileImage = File(picked.path);
        _webImage = null;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_webImage == null && _mobileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir une photo d'abord.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imageFile = _webImage ?? _mobileImage!;
      final url = await AuthService().uploadProfileImage(
        user.uid,
        imageFile,
        onProgress: (p) => setState(() => _progress = p),
      );

      if (url != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'photoUrl': url,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo enregistrée avec succès ✅")),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InterestsPage()),
          );
        }
      } else {
        throw Exception("Erreur pendant l'upload");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _webImage != null
        ? MemoryImage(_webImage!)
        : _mobileImage != null
        ? FileImage(_mobileImage!)
        : const AssetImage('assets/images/placeholder.jpg') as ImageProvider;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Ajoute ta photo de profil 📸",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 25),

              // 🧑‍🦱 Cercle photo
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.orange.shade100,
                      backgroundImage: imageProvider,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 6,
                  backgroundColor: Colors.orange.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.deepOrangeAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Téléversement : ${_progress.toStringAsFixed(1)}%"),
              ],

              const SizedBox(height: 40),

              // 🎨 Bouton stylisé et réduit
              GestureDetector(
                onTap: _isUploading ? null : _uploadPhoto,
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.5, // moitié de la largeur
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.deepOrange, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: _isUploading
                        ? const CircularProgressIndicator(
                            color: Colors.deepOrange,
                          )
                        : const Text(
                            "Enregistrer",
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
