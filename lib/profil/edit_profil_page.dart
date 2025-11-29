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
import 'package:yolo/connexions/auth_service.dart';
import 'profil.dart';

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController villeController = TextEditingController();

  DateTime? dateNaissance;
  String? region;
  String? orientation;
  String? photoUrl;
  String? gender;

  File? _newImage;
  Uint8List? _webImageBytes;

  bool _isLoading = true;
  bool _isSaving = false;
  double _uploadProgress = 0.0;

  final List<String> regions = [
    'Auvergne-Rhône-Alpes',
    'Bourgogne-Franche-Comté',
    'Bretagne',
    'Centre-Val de Loire',
    'Corse',
    'Grand Est',
    'Hauts-de-France',
    'Île-de-France',
    'Normandie',
    'Nouvelle-Aquitaine',
    'Occitanie',
    'Pays de la Loire',
    'Provence-Alpes-Côte d’Azur',
    'Guadeloupe',
    'Martinique',
    'Guyane',
    'La Réunion',
    'Mayotte',
  ];

  final List<String> orientations = [
    'Hétérosexuel(le)',
    'Homosexuel(le)',
    'Bisexuel(le)',
    'Pansexuel(le)',
    'Asexuel(le)',
    'Autre / Préfère ne pas dire',
  ];
  final List<String> genders = [
    "Homme",
    "Femme",
    "Je préfère ne pas dire"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        prenomController.text = data['firstName'] ?? '';
        bioController.text = data['bio'] ?? '';
        villeController.text = data['city'] ?? '';
        region = data['region'];
        orientation = data['orientation'];
        photoUrl = data['photoUrl'];
        gender = data['gender'];

        if (data['birthDate'] != null) {
          final raw = data['birthDate'];
          if (raw is String && raw.contains('/')) {
            final parts = raw.split('/');
            if (parts.length == 3) {
              dateNaissance = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de chargement : $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _newImage = null;
        });
      } else {
        setState(() {
          _newImage = File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _uploadProgress = 0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? newPhotoUrl = photoUrl;

      if (_newImage != null || _webImageBytes != null) {
        final imageToSend = _webImageBytes ?? _newImage!;
        newPhotoUrl = await AuthService().uploadProfileImage(
          user.uid,
          imageToSend,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'firstName': prenomController.text.trim(),
        'bio': bioController.text.trim(),
        'city': villeController.text.trim(),
        'region': region ?? '',
        'gender': gender ?? '',
        'orientation': orientation ?? '',
        'birthDate': dateNaissance != null
            ? "${dateNaissance!.day}/${dateNaissance!.month}/${dateNaissance!.year}"
            : '',
        'photoUrl': newPhotoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil mis à jour ✅"),
            backgroundColor: Colors.orangeAccent,
          ),
        );

        // Return to the previous page (profile) instead of referencing an undefined widget.
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de sauvegarde : $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final ImageProvider imageProvider = _webImageBytes != null
        ? MemoryImage(_webImageBytes!)
        : _newImage != null
        ? FileImage(_newImage!)
        : (photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/images/placeholder.jpg'))
              as ImageProvider;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 244, 198, 48), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔙 Bouton retour
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    "Modifier mon profil",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 🧑‍🦱 Photo de profil
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: imageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isSaving && _uploadProgress > 0 && _uploadProgress < 100)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 40,
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _uploadProgress / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.deepPurpleAccent,
                          ),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Téléversement : ${_uploadProgress.toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: [
                        _buildTextField("Prénom", prenomController),
                        const SizedBox(height: 16),
                        _buildDatePicker(context),
                        const SizedBox(height: 16),
                        _buildTextField("Ville", villeController),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Région",
                          region,
                          regions,
                          (val) => setState(() => region = val),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Orientation sexuelle",
                          orientation,
                          orientations,
                          (val) => setState(() => orientation = val),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Genre",
                          gender,
                          genders,
                          (val) => setState(() => gender = val),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField("Bio", bioController, maxLines: 3),
                        const SizedBox(height: 30),

                        // ✅ BOUTON "ENREGISTRER" — version compacte et centrée
                        Center(
                          child: GestureDetector(
                            onTap: _isSaving ? null : _saveProfile,
                            child: Container(
                              width: 300,
                              height: 50,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFA855F7),
                                    Color(0xFFF97316),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Enregistrer",
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: dateNaissance ?? DateTime(1990),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFFF7043),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => dateNaissance = picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          dateNaissance == null
              ? "Date de naissance"
              : "Né(e) le : ${dateNaissance!.day}/${dateNaissance!.month}/${dateNaissance!.year}",
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        dropdownColor: Colors.white,
        items: options
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
