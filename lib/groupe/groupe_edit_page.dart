import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'groupe_model.dart';
import 'groupe_chat_page.dart';
import '../profil/centre_interet_page.dart';

class StorageHelper {
  static String convert(String url) {
    if (!url.startsWith("gs://")) return url;

    final base = url.replaceFirst("gs://", "");
    final slash = base.indexOf("/");

    if (slash == -1) return url;

    final bucket = base.substring(0, slash);
    final path = Uri.encodeComponent(base.substring(slash + 1));

    return "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$path?alt=media";
  }

  static String defaultGroup() {
    return convert(
      "gs://yolo-d90ce.firebasestorage.app/group_photos/default_group.png",
    );
  }
}
// Dégradés
const LinearGradient yoloHeaderGradient = LinearGradient(
  colors: [Color.fromARGB(255, 244, 198, 48), Color(0xFFF97316)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const LinearGradient yoloBackgroundGradient = LinearGradient(
  colors: [Color(0xFFFFFBEB), Color(0xFFFFF5EE), Color(0xFFEFF6FF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class GroupeEditPage extends StatefulWidget {
  final GroupeModel groupe;

  const GroupeEditPage({super.key, required this.groupe});

  @override
  State<GroupeEditPage> createState() => _GroupeEditPageState();
}

class _GroupeEditPageState extends State<GroupeEditPage> {
  final _groupName = TextEditingController();
  final _groupDescription = TextEditingController();

  bool _saving = false;

  String _hexColor = "#A855F7";

  XFile? _pickedImage;
  Uint8List? _webBytes;
  String? _oldImageUrl;

  List<String> _interets = [];
  static const maxInterets = 5;

  // ------------------------------------------------------------
  // 🔥 initState — on charge les données du modèle (pas Firestore)
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    final g = widget.groupe;

    _groupName.text = g.nom;
    _groupDescription.text = g.description;
    _hexColor = g.couleur; // String du style "#A855F7"
    _oldImageUrl = g.photoUrl;
    _interets = List<String>.from(g.interets);
  }

  // ------------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (kIsWeb) {
      _pickedImage = file;
      _webBytes = await file.readAsBytes();
    } else {
      _pickedImage = file;
    }

    setState(() {});
  }

  // ------------------------------------------------------------
  // 🔥 Upload image : version FIABLE
  // ------------------------------------------------------------
  Future<String?> _uploadImageIfNeeded() async {
    if (_pickedImage == null) return _oldImageUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child("group_photos")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    if (kIsWeb && _webBytes != null) {
      await ref.putData(_webBytes!);
    } else {
      await ref.putFile(File(_pickedImage!.path));
    }

    return (await ref.getDownloadURL()).replaceAll('"', '').trim();
  }

  // ------------------------------------------------------------
  Future<void> _selectInterets() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CentreInteretPage(
          isGroupMode: true,
          maxGroupInterests: maxInterets,
          selectionInitiale: _interets,
        ),
      ),
    );

    if (result != null) {
      setState(() => _interets = List<String>.from(result));
    }
  }

  // ------------------------------------------------------------
  Future<void> _saveGroup() async {
    if (_groupName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le groupe doit avoir un nom.")),
      );
      return;
    }

    setState(() => _saving = true);

    final imageUrl = await _uploadImageIfNeeded();

    await FirebaseFirestore.instance
        .collection("groupes")
        .doc(widget.groupe.id)
        .update({
          "nom": _groupName.text.trim(),
          "description": _groupDescription.text.trim(),
          "photoUrl": imageUrl,
          "couleur": _hexColor,
          "interets": _interets,
        });

    if (!mounted) return;

    setState(() => _saving = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GroupeChatPage(groupeId: widget.groupe.id),
      ),
    );
  }

  // ------------------------------------------------------------
  Widget _colorSelector() {
    final options = [
      "#A855F7",
      "#F97316",
      "#10B981",
      "#3B82F6",
      "#EC4899",
      "#FACC15",
    ];

    return Wrap(
      spacing: 12,
      children: options.map((hex) {
        final selected = _hexColor == hex;

        return GestureDetector(
          onTap: () => setState(() => _hexColor = hex),
          child: Container(
            width: selected ? 44 : 36,
            height: selected ? 44 : 36,
            decoration: BoxDecoration(
              color: Color(int.parse(hex.replaceAll("#", "0xff"))),
              borderRadius: BorderRadius.circular(30),
              border: selected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  Widget _selectedInteretsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Centres d’intérêt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_interets.isEmpty)
          const Text(
            "Aucun centre d’intérêt sélectionné",
            style: TextStyle(color: Colors.black54),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interets.map((i) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(i),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _selectInterets,
          icon: const Icon(Icons.interests),
          label: const Text("Modifier les centres d’intérêt"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    ImageProvider? img;

    if (_pickedImage != null) {
      if (kIsWeb && _webBytes != null) {
        img = MemoryImage(_webBytes!);
      } else {
        img = FileImage(File(_pickedImage!.path));
      }
    } else if (_oldImageUrl?.isNotEmpty == true) {
      img = NetworkImage(_oldImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Modifier le groupe",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: yoloHeaderGradient),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: yoloBackgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PHOTO
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.orange.shade200,
                    backgroundImage: img,
                    child: img == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Nom du groupe",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupName,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 25),

              const Text(
                "Description",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupDescription,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 25),
              _selectedInteretsSection(),

              const SizedBox(height: 25),
              const Text(
                "Couleur du groupe",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _colorSelector(),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _saving ? null : _saveGroup,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sauvegarder",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
