import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profil/centre_interet_page.dart';
import 'groupe_chat_page.dart';

// -----------------------------------------------------------------------------
// 🔥 Helper universel pour convertir gs:// → https
// -----------------------------------------------------------------------------
class StorageHelper {
  static String convert(String url) {
    if (!url.startsWith("gs://")) return url;

    final base = url.replaceFirst("gs://", "");
    final slash = base.indexOf("/");
    if (slash == -1) return url;

    final bucket = base.substring(0, slash);
    final path = Uri.encodeComponent(base.substring(slash + 1));

    return "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$path?alt=media&v=1";
  }

  static String defaultGroup() {
    return convert(
      "gs://yolo-d90ce.firebasestorage.app/group_photos/default_group.png",
    );
  }
}

// -----------------------------------------------------------------------------
// 🟦 PAGE CREATION DE GROUPE
// -----------------------------------------------------------------------------
class GroupeCreationPage extends StatefulWidget {
  const GroupeCreationPage({super.key});

  @override
  State<GroupeCreationPage> createState() => _GroupeCreationPageState();
}

class _GroupeCreationPageState extends State<GroupeCreationPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser!;

  bool isLoading = false;

  // 🔥 Groupe toujours PUBLIC
  bool isPublic = true;

  // Image
  Uint8List? imageBytes;
  XFile? pickedImage;

  // Couleur = INT Firestore
  int groupColor = 0xffCD0D4D;

  // Centres d’intérêt
  List<String> interetsSelectionnes = [];

  // ---------------------------------------------------------------------------
  // PICK IMAGE
  // ---------------------------------------------------------------------------
  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;

    pickedImage = img;
    imageBytes = await img.readAsBytes();

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // UPLOAD IMAGE
  // ---------------------------------------------------------------------------
  Future<String> _uploadImage() async {
    if (imageBytes != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child("group_photos")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putData(
        imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    }

    return StorageHelper.defaultGroup();
  }

  // ---------------------------------------------------------------------------
  // SELECT INTERETS
  // ---------------------------------------------------------------------------
  Future<void> _selectInterets() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CentreInteretPage(
          isGroupMode: true,
          maxGroupInterests: 5,
          selectionInitiale: interetsSelectionnes,
        ),
      ),
    );

    if (result != null) {
      setState(() => interetsSelectionnes = List<String>.from(result));
    }
  }

  // ---------------------------------------------------------------------------
  // CREATION DU GROUPE
  // ---------------------------------------------------------------------------
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (interetsSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoute au moins un centre d’intérêt.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final photoUrl = await _uploadImage();

      final ref = FirebaseFirestore.instance.collection("groupes").doc();

      await ref.set({
        "id": ref.id,
        "nom": nameController.text.trim(),
        "description": descController.text.trim(),
        "photoUrl": photoUrl,
        "createurId": user.uid,
        "membres": [user.uid],
        "admins": [user.uid],
        "bannis": [],
        "interets": interetsSelectionnes,
        "couleur": groupColor,
        "isPublic": isPublic, // 🔥 toujours public
        "prive": false, // 🔥 sécurité
        "lastMessage": "",
        "lastTime": FieldValue.serverTimestamp(),
        "unreadBy": [],
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GroupeChatPage(groupeId: ref.id)),
      );
    } catch (e) {
      debugPrint("Erreur création groupe : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de la création du groupe."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(groupColor),
        title: const Text(
          "Créer un groupe",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // PHOTO
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Color(groupColor).withOpacity(0.4),
                  backgroundImage: imageBytes != null
                      ? MemoryImage(imageBytes!)
                      : NetworkImage(StorageHelper.defaultGroup()),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Couleur du groupe",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _colorDot(0xff55CCF7),
                  _colorDot(0xffF97316),
                  _colorDot(0xff10B981),
                  _colorDot(0xff3B82F6),
                  _colorDot(0xffEC4899),
                ],
              ),

              const SizedBox(height: 25),

              // INTÉRÊTS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Centres d’intérêt",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (interetsSelectionnes.isEmpty)
                      const Text(
                        "Aucun centre sélectionné",
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: interetsSelectionnes
                            .map(
                              (i) => Chip(
                                label: Text(i),
                                backgroundColor: Color(
                                  groupColor,
                                ).withOpacity(0.25),
                              ),
                            )
                            .toList(),
                      ),

                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(groupColor),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _selectInterets,
                      child: const Text("Modifier"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: nameController,
                decoration: _input("Nom du groupe"),
                validator: (v) => v!.isEmpty ? "Nom obligatoire" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: descController,
                maxLines: 3,
                decoration: _input("Description"),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Color(groupColor),
                  ),
                  onPressed: isLoading ? null : _createGroup,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Créer le groupe",
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET SELECTEUR COULEUR
  // ---------------------------------------------------------------------------
  Widget _colorDot(int colorInt) {
    final selected = groupColor == colorInt;

    return GestureDetector(
      onTap: () => setState(() => groupColor = colorInt),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(radius: 12, backgroundColor: Color(colorInt)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT STYLE
  // ---------------------------------------------------------------------------
  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
