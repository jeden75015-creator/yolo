import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import 'activite_model.dart';
import 'activite_service.dart';
import 'categorie_data.dart';
import 'package:yolo/widgets/regions.dart';

class ActiviteModificationPage extends StatefulWidget {
  final Activite activite;

  const ActiviteModificationPage({super.key, required this.activite});

  @override
  State<ActiviteModificationPage> createState() =>
      _ActiviteModificationPageState();
}

class _ActiviteModificationPageState extends State<ActiviteModificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ActiviteService();

  late TextEditingController titre;
  late TextEditingController description;
  late TextEditingController adresse;
  late TextEditingController maxParticipants;

  DateTime? date;
  String? region;
  late String categorie; // Toujours non-nullable

  Uint8List? _webImage;
  File? _localImage;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    titre = TextEditingController(text: widget.activite.titre);
    description = TextEditingController(text: widget.activite.description);
    adresse = TextEditingController(text: widget.activite.adresse);
    maxParticipants = TextEditingController(
      text: widget.activite.maxParticipants.toString(),
    );

    // --- Correction catégorie avec fallback sûr ---
    final initialCat = widget.activite.categorie;
    categorie = CategorieData.categories.containsKey(initialCat)
        ? initialCat
        : CategorieData.categories.keys.first;

    date = widget.activite.date;
    region = widget.activite.region;
  }

  // --------------------------------------------------------
  // 🔥 Choisir une image
  // --------------------------------------------------------
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImage = bytes;
        _localImage = null;
      });
    } else {
      setState(() {
        _localImage = File(picked.path);
        _webImage = null;
      });
    }
  }

  // --------------------------------------------------------
  // 🔥 Upload image si nécessaire
  // --------------------------------------------------------
  Future<String?> uploadIfNeeded() async {
    if (_webImage == null && _localImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child("activites/${widget.activite.id}/photo.jpg");

    UploadTask task;

    if (kIsWeb) {
      task = ref.putData(_webImage!);
    } else {
      task = ref.putFile(_localImage!);
    }

    final snap = await task;
    return snap.ref.getDownloadURL();
  }

  // --------------------------------------------------------
  // 🔥 Sauvegarde
  // --------------------------------------------------------
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final newPhoto = await uploadIfNeeded();

    await _service.modifierActivite(
      activiteId: widget.activite.id,
      titre: titre.text.trim(),
      description: description.text.trim(),
      adresse: adresse.text.trim(),
      region: region ?? widget.activite.region,
      photoUrl: newPhoto ?? widget.activite.photoUrl,
      date: date ?? widget.activite.date,
      categorie: categorie, // ✔ toujours valide
      maxParticipants: int.tryParse(maxParticipants.text) ??
          widget.activite.maxParticipants,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // --------------------------------------------------------
  // 🔥 UI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final catData = CategorieData.categories[categorie];
    final color = catData?["color"] ?? Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier l’activité"),
        backgroundColor: color,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // --------------------------------------------------------
              // 📸 Image activité
              // --------------------------------------------------------
              GestureDetector(
                onTap: pickImage,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: _webImage != null
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : _localImage != null
                                ? Image.file(_localImage!, fit: BoxFit.cover)
                                : Image.network(
                                    widget.activite.photoUrl,
                                    fit: BoxFit.cover,
                                  ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 14),
                            SizedBox(width: 6),
                            Text("Modifier"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // --------------------------------------------------------
              // 📝 Champs
              // --------------------------------------------------------

              TextFormField(
                controller: titre,
                decoration: const InputDecoration(labelText: "Titre"),
                validator: (v) => v == null || v.isEmpty
                    ? "Champ obligatoire"
                    : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Description"),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: adresse,
                decoration: const InputDecoration(labelText: "Adresse"),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: region,
                decoration: const InputDecoration(labelText: "Région"),
                items: regionsFrancaises
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => region = v),
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------------
              // 🟧 Catégorie + Fallback sécurisé
              // --------------------------------------------------------
              DropdownButtonFormField<String>(
                value: categorie,
                decoration: const InputDecoration(labelText: "Catégorie"),
                items: CategorieData.categories.keys
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => categorie = v);
                  }
                },
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2050),
                  );

                  if (d != null) {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        date ?? DateTime.now(),
                      ),
                    );

                    if (t != null) {
                      setState(() {
                        date = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE d MMM yyyy — HH:mm', "fr_FR")
                            .format(date ?? widget.activite.date),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: maxParticipants,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Participants max"),
              ),

              const SizedBox(height: 26),

              GestureDetector(
                onTap: loading ? null : save,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Enregistrer",
                            style: TextStyle(
                              color: Colors.white,
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
