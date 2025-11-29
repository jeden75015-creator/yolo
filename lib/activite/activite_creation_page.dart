// -----------------------------------------------------------------------------
// 📄 PAGE : ActiviteCreationPage (YOLO — Pré-remplissage depuis Event)
// -----------------------------------------------------------------------------
// 🌟 Version entièrement corrigée et prête à l'emploi
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'activite_model.dart';
import 'activite_service.dart';
import 'categorie_data.dart';
import 'activite_fiche_page.dart';

class ActiviteCreationPage extends StatefulWidget {
  final String? categorieInitiale;

  // ---- Paramètres pré-remplis depuis Event ----
  final String? preTitle;
  final DateTime? preDate;
  final String? preAdresse;
  final String? preImage; // URL de l’image d’event

  const ActiviteCreationPage({
    super.key,
    this.categorieInitiale,
    this.preTitle,
    this.preDate,
    this.preAdresse,
    this.preImage,
  });

  @override
  State<ActiviteCreationPage> createState() => _ActiviteCreationPageState();
}

class _ActiviteCreationPageState extends State<ActiviteCreationPage> {
  // FORM
  final _formKey = GlobalKey<FormState>();
  final titre = TextEditingController();
  final description = TextEditingController();
  final adresse = TextEditingController();
  final duree = TextEditingController();

  DateTime? dateChoisie;
  bool gratuite = true;
  bool modeDiscret = false;
  int maxParticipants = 10;
  bool _saving = false;

  // REGION
  String? region;

  // IMAGE
  File? _localImage;
  Uint8List? _webImage;
  String? _eventImageUrl; // image importée depuis Event

  // ORGANISATEURS
  final List<String> organisateurs = [];

  // CATEGORIE
  String? categorie;

  final List<String> regionsFrance = const [
    "Île-de-France",
    "Centre-Val de Loire",
    "Bourgogne-Franche-Comté",
    "Normandie",
    "Hauts-de-France",
    "Grand Est",
    "Pays de la Loire",
    "Bretagne",
    "Nouvelle-Aquitaine",
    "Occitanie",
    "Auvergne-Rhône-Alpes",
    "Provence-Alpes-Côte d'Azur",
    "Corse",
    "Guadeloupe",
    "Martinique",
    "La Réunion",
    "Guyane",
    "Mayotte",
  ];

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) organisateurs.add(uid);

    categorie = widget.categorieInitiale;

    // ---- Pré-remplissage depuis l’événement ----
    if (widget.preTitle != null) titre.text = widget.preTitle!;
    if (widget.preAdresse != null) adresse.text = widget.preAdresse!;
    if (widget.preDate != null) dateChoisie = widget.preDate!;
    if (widget.preImage != null) _eventImageUrl = widget.preImage;
  }

  // -----------------------------------------------------------------------------
  // PICK IMAGE
  // -----------------------------------------------------------------------------
  Future<void> _pickImage() async {
    final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pick == null) return;

    if (kIsWeb) {
      final bytes = await pick.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      setState(() => _localImage = File(pick.path));
    }
  }

  // -----------------------------------------------------------------------------
  // UPLOAD IMAGE
  // -----------------------------------------------------------------------------
  Future<String?> _uploadImage(String id, String defaultImg) async {
    try {
      // si aucune image choisie : garde l'image par défaut
      if (_webImage == null && _localImage == null) return defaultImg;

      final ref = FirebaseStorage.instance.ref().child("activites/$id.jpg");
      UploadTask task;

      if (_webImage != null) {
        task = ref.putData(_webImage!);
      } else {
        task = ref.putFile(_localImage!);
      }

      final snap = await task;
      return snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erreur upload image $e");
      return defaultImg;
    }
  }

  // -----------------------------------------------------------------------------
  // DATE PICKER
  // -----------------------------------------------------------------------------
  Future<void> _choisirDate() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: dateChoisie ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 00),
    );

    if (t != null) {
      setState(() {
        dateChoisie = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      });
    }
  }

  // -----------------------------------------------------------------------------
  // GÉOCODAGE adresse → lat lon
  // -----------------------------------------------------------------------------
  Future<Map<String, double>?> _geocodeAdresse(String text) async {
    try {
      final url = Uri.https("maps.googleapis.com", "/maps/api/geocode/json", {
        "address": text,
        "key": "YOUR_GOOGLE_API_KEY",
      });

      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data["status"] != "OK") return null;

      final loc = data["results"][0]["geometry"]["location"];
      return {"lat": loc["lat"] * 1.0, "lng": loc["lng"] * 1.0};
    } catch (e) {
      debugPrint("Erreur géocodage: $e");
      return null;
    }
  }

  // -----------------------------------------------------------------------------
  // CRÉER ACTIVITÉ
  // -----------------------------------------------------------------------------
  Future<void> _creer() async {
    if (!_formKey.currentState!.validate() ||
        dateChoisie == null ||
        categorie == null ||
        region == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci de remplir tous les champs 🌟")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final id = FirebaseFirestore.instance.collection("activites").doc().id;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "inconnu";

      final geo = await _geocodeAdresse(adresse.text.trim());
      if (geo == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Adresse introuvable ❌")));
        return;
      }

      // priorité : image choisie > image Event > image catégorie
      final defImg =
          _eventImageUrl ?? CategorieData.categories[categorie]!["image"];

      final photoUrl = await _uploadImage(id, defImg);

      final act = Activite(
        id: id,
        titre: titre.text.trim(),
        description: description.text.trim(),
        photoUrl: photoUrl!,
        date: dateChoisie!,
        estGratuite: gratuite,
        adresse: adresse.text.trim(),
        region: region!,
        maxParticipants: maxParticipants,
        createurId: uid,
        categorie: categorie!,
        modeDiscret: modeDiscret,
        participants: [uid],
        participantsAttente: [],
        organisateurs: organisateurs,
        duree: duree.text.trim().isEmpty ? null : duree.text.trim(),
        notified3hBefore: false,
        latitude: geo["lat"]!,
        longitude: geo["lng"]!,
      );

      await ActiviteService().creerActivite(act);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ActiviteFichePage(activiteId: id)),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  // -----------------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final textColor =
        CategorieData.categories[categorie]?["textColor"] ?? Colors.black;
    final themeColor =
        CategorieData.categories[categorie]?["color"] ?? Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text("Créer une activité", style: TextStyle(color: textColor)),
        backgroundColor: themeColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(textColor, themeColor),
    );
  }

  // -----------------------------------------------------------------------------
  // BODY
  // -----------------------------------------------------------------------------
  Widget _buildBody(Color textColor, Color themeColor) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF5EE), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _field("Titre", titre, textColor),
                            const SizedBox(height: 14),

                            _field(
                              "Description",
                              description,
                              textColor,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),

                            _dropCategorie(textColor),
                            const SizedBox(height: 14),

                            _datePicker(textColor),
                            const SizedBox(height: 14),

                            _field("Durée (ex : 2h, 1h30)", duree, textColor),
                            const SizedBox(height: 14),

                            _field("Adresse", adresse, textColor),
                            const SizedBox(height: 14),

                            _dropRegion(textColor),
                            const SizedBox(height: 14),

                            _imagePicker(textColor),
                            const SizedBox(height: 20),

                            _switcher(
                              "Mode discret",
                              modeDiscret,
                              (v) => setState(() => modeDiscret = v),
                              textColor,
                            ),
                            _switcher(
                              "Activité gratuite",
                              gratuite,
                              (v) => setState(() => gratuite = v),
                              textColor,
                            ),

                            const SizedBox(height: 12),

                            _dropParticipants(textColor),
                            const SizedBox(height: 26),

                            _boutonValider(textColor, themeColor),
                            const SizedBox(height: 40),
                          ],
                        ),
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

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------

  Widget _field(
    String label,
    TextEditingController c,
    Color textColor, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      validator: (v) => v == null || v.isEmpty ? "Champ obligatoire" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropCategorie(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _box(),
      child: DropdownButtonFormField<String>(
        value: categorie,
        isExpanded: true,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: "Catégorie",
          labelStyle: TextStyle(color: textColor),
          border: InputBorder.none,
        ),
        items: CategorieData.categories.entries.map((e) {
          return DropdownMenuItem(
            value: e.key,
            child: Row(
              children: [
                Text(e.value["emoji"], style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(e.key, style: TextStyle(color: textColor)),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            categorie = v;
            _webImage = null;
            _localImage = null;
          });
        },
        validator: (v) => v == null ? "Sélectionne une catégorie" : null,
      ),
    );
  }

  Widget _dropRegion(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _box(),
      child: DropdownButtonFormField<String>(
        value: region,
        isExpanded: true,
        menuMaxHeight: 600,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: "Région",
          labelStyle: TextStyle(color: textColor),
          border: InputBorder.none,
        ),
        items: regionsFrance
            .map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text(r, style: TextStyle(color: textColor)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => region = v),
        validator: (v) => v == null ? "Sélectionne une région" : null,
      ),
    );
  }

  Widget _datePicker(Color textColor) {
    return GestureDetector(
      onTap: _choisirDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: _box(),
        child: Text(
          dateChoisie == null
              ? "Choisir une date"
              : "${dateChoisie!.day}/${dateChoisie!.month}/${dateChoisie!.year} "
                    "${dateChoisie!.hour}h${dateChoisie!.minute.toString().padLeft(2, '0')}",
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _dropParticipants(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _box(),
      child: DropdownButtonFormField<String>(
        value: maxParticipants.toString(),
        isExpanded: true,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: "Participants max",
          labelStyle: TextStyle(color: textColor),
          border: InputBorder.none,
        ),
        items: List.generate(20, (i) => (i + 1).toString())
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: TextStyle(color: textColor)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => maxParticipants = int.parse(v!)),
      ),
    );
  }

  Widget _switcher(
    String text,
    bool v,
    Function(bool) onChange,
    Color textColor,
  ) {
    return SwitchListTile(
      title: Text(text, style: TextStyle(color: textColor)),
      value: v,
      activeColor: Colors.orange,
      onChanged: onChange,
    );
  }

  Widget _imagePicker(Color textColor) {
    // priorité : image choisie > image Event > image catégorie
    final defaultImage = (categorie != null)
        ? CategorieData.categories[categorie]!["image"]
        : null;

    final img = _webImage != null
        ? Image.memory(_webImage!, fit: BoxFit.cover)
        : _localImage != null
        ? Image.file(_localImage!, fit: BoxFit.cover)
        : (_eventImageUrl != null)
        ? Image.network(_eventImageUrl!, fit: BoxFit.cover)
        : (defaultImage != null
              ? Image.network(defaultImage, fit: BoxFit.cover)
              : null);

    return Stack(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child:
              img ??
              Icon(
                Icons.camera_alt,
                color: textColor.withOpacity(0.5),
                size: 34,
              ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Modifier l’image",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _boutonValider(Color textColor, Color themeColor) {
    return GestureDetector(
      onTap: _saving ? null : _creer,
      child: Container(
        height: 50,
        width: 230,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeColor, themeColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: _saving
              ? CircularProgressIndicator(color: textColor)
              : Text(
                  "Créer l’activité",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black12),
    );
  }
}
