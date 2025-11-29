// -----------------------------------------------------------------------------
// 📄 PAGE : ActiviteChatPage – VERSION PREMIUM 2025 OPTIMISÉE
// + Réponse sur TOUT (texte, image, GIF, localisation)
// + Menu flottant style WhatsApp (copier / répondre / éditer / supprimer / réactions)
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'activite_model.dart';
import 'activite_service.dart';
import 'categorie_data.dart';
import 'activite_fiche_page.dart';
import 'modal_helpers.dart';

const String TENOR_API_KEY = "AIzaSyDSz2OEbEyLz02OKQ5imsw3Q0u1z3v2qWY";
const String GOOGLE_STATIC_MAPS_KEY = "AIzaSyBfm6IoyNEj8mCtnMCjOy-dsOELJt0efpk";

class ActiviteChatPage extends StatefulWidget {
  final String activiteId;
  const ActiviteChatPage({super.key, required this.activiteId});

  @override
  State<ActiviteChatPage> createState() => _ActiviteChatPageState();
}

class _ActiviteChatPageState extends State<ActiviteChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final ActiviteService _service = ActiviteService();

  Activite? _activite;
  bool _loading = true;
  Timer? _typingTimer;

  File? _pendingImageFile;
  Uint8List? _pendingImageBytes;

  // 🔥 Réponse (local + servie dans Firestore via "replyTo")
  Map<String, dynamic>? _replyingTo;

  // 🔥 Édition (texte uniquement)
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _loadActivite();
    _service.markAsRead(widget.activiteId); // marquer lu dès l'ouverture
  }

  Future<void> _loadActivite() async {
    final act = await _service.getActivite(widget.activiteId);
    if (!mounted) return;
    setState(() {
      _activite = act;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  bool get _canWrite {
    if (_activite == null) return false;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return _activite!.createurId == uid ||
        _activite!.participants.contains(uid);
  }

  // ---------------------------------------------------------------------------
  // SCROLL AUTO EN BAS
  // ---------------------------------------------------------------------------
  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // SET TYPING
  // ---------------------------------------------------------------------------
  Future<void> _setTyping(bool typing) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("activites")
        .doc(widget.activiteId)
        .collection("typing")
        .doc(uid)
        .set({
      "userId": uid,
      "isTyping": typing,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // ENVOI MESSAGE (texte + image + reply + edit)
  // ---------------------------------------------------------------------------
  Future<void> _sendMessage() async {
    if (_activite == null) return;
    if (!_canWrite) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final rawText = _controller.text.trim();

    final bool hasText = rawText.isNotEmpty;
    final bool hasPendingImage =
        _pendingImageFile != null || _pendingImageBytes != null;

    if (!hasText && !hasPendingImage) {
      return;
    }

    String? imageUrl;

    try {
      // ✅ Upload image si nécessaire
      if (hasPendingImage) {
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child("activites/${widget.activiteId}/chat/$fileName");

        UploadTask uploadTask;
        if (kIsWeb && _pendingImageBytes != null) {
          uploadTask = ref.putData(
            _pendingImageBytes!,
            SettableMetadata(contentType: "image/jpeg"),
          );
        } else if (_pendingImageFile != null) {
          uploadTask = ref.putFile(_pendingImageFile!);
        } else {
          uploadTask = ref.putData(
            _pendingImageBytes!,
            SettableMetadata(contentType: "image/jpeg"),
          );
        }

        final snap = await uploadTask;
        imageUrl = await snap.ref.getDownloadURL();
      }

      final chatCol = FirebaseFirestore.instance
          .collection("activites")
          .doc(widget.activiteId)
          .collection("chat");

      // ✏️ MODE ÉDITION (texte uniquement, pas de nouvelle image)
      if (_editingMessageId != null && imageUrl == null) {
        await chatCol.doc(_editingMessageId).update({
          if (hasText) "message": rawText,
          if (!hasText) "message": FieldValue.delete(),
        });

        setState(() {
          _controller.clear();
          _pendingImageFile = null;
          _pendingImageBytes = null;
          _editingMessageId = null;
          _replyingTo = null;
        });
        _setTyping(false);
        Future.delayed(const Duration(milliseconds: 120), _autoScroll);
        return;
      }

      // ✉️ ENVOI NORMAL
      final Map<String, dynamic> payload = {
        "userId": uid,
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (hasText) {
        payload["message"] = rawText;
      }
      if (imageUrl != null) {
        payload["imageUrl"] = imageUrl;
      }

      // 🧷 Ajouter les infos de reply structurées
      if (_replyingTo != null) {
        payload["replyTo"] = {
          "messageId": _replyingTo!["messageId"],
          "preview": _replyingTo!["preview"] ?? "",
          "hasImage": _replyingTo!["hasImage"] ?? false,
          "hasGif": _replyingTo!["hasGif"] ?? false,
          "hasLocation": _replyingTo!["hasLocation"] ?? false,
        };
      }

      await chatCol.add(payload);

      // 🔥 Met à jour la messagerie Activités
      final lastLabel = hasText
          ? rawText
          : (imageUrl != null ? "📸 Photo" : "Message");
      await _service.updateLastMessage(widget.activiteId, lastLabel);

      setState(() {
        _controller.clear();
        _pendingImageFile = null;
        _pendingImageBytes = null;
        _replyingTo = null;
        _editingMessageId = null;
      });
      _setTyping(false);

      Future.delayed(const Duration(milliseconds: 120), _autoScroll);
    } catch (e) {
      debugPrint("🔥 ERREUR ENVOI MESSAGE : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'envoyer le message pour l’instant."),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ENVOYER UN GIF
  // ---------------------------------------------------------------------------
  Future<void> _sendGif(String gifUrl) async {
    if (_activite == null || !_canWrite) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final chatCol = FirebaseFirestore.instance
        .collection("activites")
        .doc(widget.activiteId)
        .collection("chat");

    final payload = {
      "userId": uid,
      "gifUrl": gifUrl,
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (_replyingTo != null) {
      payload["replyTo"] = {
        "messageId": _replyingTo!["messageId"],
        "preview": _replyingTo!["preview"] ?? "",
        "hasImage": _replyingTo!["hasImage"] ?? false,
        "hasGif": _replyingTo!["hasGif"] ?? false,
        "hasLocation": _replyingTo!["hasLocation"] ?? false,
      };
    }

    await chatCol.add(payload);

    await _service.updateLastMessage(widget.activiteId, "GIF envoyé");

    setState(() {
      _replyingTo = null;
    });

    Future.delayed(const Duration(milliseconds: 120), _autoScroll);
  }

  // ---------------------------------------------------------------------------
  // REACTIONS : liste simple d'emojis stockés dans un array "reactions"
  // ---------------------------------------------------------------------------
  /// ---------------------------------------------------------------------------
  // TOGGLE REACTION : ajoute ou retire UNE réaction de l'utilisateur
  // mais permet plusieurs mêmes emojis sur le message.
  // Exemple : ["❤️","❤️","😂","😂","😂"]
  // ---------------------------------------------------------------------------
  Future<void> _toggleReaction(String messageId, String emoji) async {
    final ref = FirebaseFirestore.instance
        .collection("activites")
        .doc(widget.activiteId)
        .collection("chat")
        .doc(messageId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> list = List<dynamic>.from(data["reactions"] ?? []);

    // 👉 Ajoute une réaction (toujours)
    // On NE supprime pas les anciennes, car tu veux plusieurs mêmes emojis
      list.add(emoji);

      tx.update(ref, {"reactions": list});
    });
  }
  // ---------------------------------------------------------------------------
  // PICK IMAGE
  // ---------------------------------------------------------------------------
  Future<void> _pickImage() async {
    if (!_canWrite) return;

    try {
      final picker = ImagePicker();
      final XFile? file =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

      if (file == null) return;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pendingImageBytes = bytes;
          _pendingImageFile = null;
        });
      } else {
        setState(() {
          _pendingImageFile = File(file.path);
          _pendingImageBytes = null;
        });
      }
    } catch (e) {
      debugPrint("🔥 ERREUR PICK IMAGE : $e");
    }
  }

  // ---------------------------------------------------------------------------
  // ENVOI LOCALISATION
  // ---------------------------------------------------------------------------
  Future<void> _sendLocation() async {
    if (!_canWrite) return;

    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Active la localisation pour partager ta position.")),
        );
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Permission localisation refusée en permanence.")),
        );
        return;
      }
      // 📍 Attendre un vrai FIX GPS
      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      final pos = await positionStream.firstWhere(
        (p) => p.accuracy < 50,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () async {
        // fallback si pas de fix GPS
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        },
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final chatCol = FirebaseFirestore.instance
          .collection("activites")
          .doc(widget.activiteId)
          .collection("chat");

      final payload = {
        "userId": uid,
        "location": {
          "lat": pos.latitude,
          "lng": pos.longitude,
          "address": "Localisation",
        },
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (_replyingTo != null) {
        payload["replyTo"] = {
          "messageId": _replyingTo!["messageId"],
          "preview": _replyingTo!["preview"] ?? "",
          "hasImage": _replyingTo!["hasImage"] ?? false,
          "hasGif": _replyingTo!["hasGif"] ?? false,
          "hasLocation": true,
        };
      }

      await chatCol.add(payload);

      await _service.updateLastMessage(
        widget.activiteId,
        "📍 Localisation partagée",
      );

      setState(() {
        _replyingTo = null;
      });

      Future.delayed(const Duration(milliseconds: 120), _autoScroll);
    } catch (e) {
      debugPrint("🔥 ERREUR ENVOI LOCALISATION : $e");
    }
  }

  // ---------------------------------------------------------------------------
  // OUVRIR LE PICKER TENOR (GIF) – version stable
  // ---------------------------------------------------------------------------
  Future<void> _openGifPicker() async {
    if (!_canWrite) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _gifPickerModal(),
    );
  }

  Widget _gifPickerModal() {
    final TextEditingController searchCtrl = TextEditingController();
    List gifs = [];
    bool isLoading = true;

    Future<void> loadGifs(String q, void Function(void Function()) sbSetState) async {
      String url;
      if (q.isEmpty) {
        url =
            "https://tenor.googleapis.com/v2/featured?key=$TENOR_API_KEY&limit=30&media_filter=gif";
      } else {
        url =
            "https://tenor.googleapis.com/v2/search?q=$q&key=$TENOR_API_KEY&limit=30&media_filter=gif";
      }

      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          gifs = data["results"] ?? [];
        }
      } catch (e) {
        debugPrint("🔥 ERREUR TENOR : $e");
      }

      sbSetState(() {
        isLoading = false;
      });
    }

    return SafeArea(
      child: StatefulBuilder(
        builder: (context, sbSetState) {
          // Charger trending au premier build
          if (isLoading && gifs.isEmpty) {
            loadGifs("", sbSetState);
          }

          return Container(
            padding: const EdgeInsets.all(12),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Rechercher un GIF...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (v) {
                    sbSetState(() {
                      isLoading = true;
                      gifs = [];
                    });
                    loadGifs(v.trim(), sbSetState);
                  },
                ),
                const SizedBox(height: 10),
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      itemCount: gifs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (_, i) {
                        final gif = gifs[i];
                        final media = gif["media_formats"];
                        final gifUrl = media["gif"]["url"];

                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await _sendGif(gifUrl);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              gifUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUPPRESSION MESSAGE (avec suppression image éventuelle)
  // ---------------------------------------------------------------------------
  Future<void> _deleteChatMessage(String messageId, {String? imageUrl}) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection("activites")
          .doc(widget.activiteId)
          .collection("chat")
          .doc(messageId);

      final snap = await ref.get();
      final data = snap.data();

      final img = imageUrl ?? data?["imageUrl"];

      if (img != null && img.toString().isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(img).delete();
        } catch (_) {}
      }

      await ref.delete();
    } catch (e) {
      debugPrint("🔥 ERREUR SUPPRESSION MESSAGE : $e");
    }
  }

  // ---------------------------------------------------------------------------
  // MENU D'ACTIONS POUR UN MESSAGE
  // ---------------------------------------------------------------------------
  void _openMessageActionsModal({
    required String messageId,
    required bool isMe,
    required String? text,
    required String? imageUrl,
    required String? gifUrl,
    required Map<String, dynamic>? location,
  }) {
    final bool hasText = text != null && text.trim().isNotEmpty;
    final bool hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final bool hasGif = gifUrl != null && gifUrl.trim().isNotEmpty;
    final bool hasLocation = location != null;

    final bool canEdit = isMe && hasText && !hasImage && !hasGif && !hasLocation;

    String buildPreview() {
      if (hasText) {
        final s = text!.trim();
        return s.length > 70 ? "${s.substring(0, 70)}…" : s;
      }
      if (hasImage) return "📸 Photo";
      if (hasGif) return "GIF";
      if (hasLocation) return "📍 Localisation";
      return "Message";
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ligne de réactions
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in const ["❤️", "😂", "👍", "😮", "😢", "😡"])
                      GestureDetector(
                        onTap: () async {
                          await _toggleReaction(messageId, emoji);
                          Navigator.pop(context);
                        },
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Répondre (sur TOUT type de message)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text("Répondre"),
                onTap: () {
                  setState(() {
                    _replyingTo = {
                      "messageId": messageId,
                      "preview": buildPreview(),
                      "hasImage": hasImage,
                      "hasGif": hasGif,
                      "hasLocation": hasLocation,
                    };
                    _editingMessageId = null;
                  });
                  Navigator.pop(context);
                },
              ),

              // Copier (texte uniquement)
              if (hasText)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text("Copier"),
                  onTap: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: text!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Message copié"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Clipboard error: $e");
                    }
                    Navigator.pop(context);
                  },
                ),

              // Modifier
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Modifier"),
                  onTap: () {
                    setState(() {
                      _editingMessageId = messageId;
                      _controller.text = text;
                      _replyingTo = null;
                    });
                    Navigator.pop(context);
                  },
                ),

              // Supprimer
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Supprimer"),
                  onTap: () async {
                    await _deleteChatMessage(messageId, imageUrl: imageUrl);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  // ---------------------------------------------------------------------------
  // UI PRINCIPALE
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading || _activite == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final categoryColor =
        CategorieData.categories[_activite!.categorie]?['color'] ??
            Colors.deepPurple;

    return Scaffold(
      body: Stack(
        children: [
          // Fond dégradé
          Container(
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
          ),

          // Bulles translucides
          Positioned(
            top: -60,
            left: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _header(categoryColor),
                Expanded(child: _messageList()),
                if (!_canWrite)
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.red.withOpacity(0.12),
                    child: const Text(
                      "Vous devez être inscrit à l'activité pour pouvoir envoyer un message.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _imagePreview(),
                _buildReplyOrEditBar(),
                _inputBar(categoryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LISTE DES MESSAGES
  // ---------------------------------------------------------------------------
  Widget _messageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("activites")
          .doc(widget.activiteId)
          .collection("chat")
          .orderBy("createdAt")
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          debugPrint("🔥 ERREUR STREAM CHAT : ${snap.error}");
        }
        if (!snap.hasData) return const SizedBox();

        final docs = snap.data!.docs;
        
        _service.markAsRead(widget.activiteId);
        _autoScroll();
        
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final userId = data["userId"];
            final text = data["message"];
            final imageUrl = data["imageUrl"];
            final gifUrl = data["gifUrl"];
            final location = data["location"];
            final ts = data["createdAt"] as Timestamp?;
            final date = ts?.toDate();
            final reactions = data["reactions"] as List<dynamic>?;
            final replyTo =
                data["replyTo"] != null && data["replyTo"] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(data["replyTo"])
                    : null;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .get(),
              builder: (_, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const SizedBox();
                }

                final u = userSnap.data!.data() as Map<String, dynamic>;
                final prenom = u["firstName"] ?? "Profil";
                final photo = u["photoUrl"] ?? "";
                final currentUid = FirebaseAuth.instance.currentUser!.uid;
                final bool isMe = userId == currentUid;
                final bool isCreator = userId == _activite!.createurId;

                final categoryColor =
                    CategorieData.categories[_activite!.categorie]?['color'] ??
                        Colors.deepPurple;

                return _messageBubble(
                  messageId: docs[i].id,
                  prenom: prenom,
                  photo: photo,
                  text: text?.toString(),
                  imageUrl: imageUrl?.toString(),
                  gifUrl: gifUrl?.toString(),
                  location: location != null
                      ? Map<String, dynamic>.from(location)
                      : null,
                  reactions: reactions,
                  replyTo: replyTo,
                  isMe: isMe,
                  isCreator: isCreator,
                  date: date,
                  color: categoryColor,
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PRÉVISU IMAGE EN COURS
  // ---------------------------------------------------------------------------
  Widget _imagePreview() {
    if (_pendingImageFile == null && _pendingImageBytes == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _pendingImageBytes != null
                ? Image.memory(
                    _pendingImageBytes!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    _pendingImageFile!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 10),
          const Text(
            "Photo prête à envoyer",
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _pendingImageBytes = null;
                _pendingImageFile = null;
              });
            },
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRE REPLY / EDIT
  // ---------------------------------------------------------------------------
  Widget _buildReplyOrEditBar() {
    if (_editingMessageId == null && _replyingTo == null) {
      return const SizedBox.shrink();
    }

    String label;
    String content;

    if (_editingMessageId != null) {
      label = "Modification du message";
      content = _controller.text;
    } else {
      label = "Répondre à ce message";
      content = (_replyingTo?["preview"] ?? "").toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: const Border(
          top: BorderSide(color: Colors.grey),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _editingMessageId = null;
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BARRE D'INPUT
  // ---------------------------------------------------------------------------
  Widget _inputBar(Color categoryColor) {
    final canWrite = _canWrite;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: categoryColor.withOpacity(0.98),
      child: Row(
        children: [
          GestureDetector(
            onTap: canWrite ? _pickImage : null,
            child: Opacity(
              opacity: canWrite ? 1.0 : 0.4,
              child: const Icon(Icons.photo, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canWrite ? _sendLocation : null,
            child: Opacity(
              opacity: canWrite ? 1.0 : 0.4,
              child: const Icon(Icons.location_on, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canWrite ? _openGifPicker : null,
            child: Opacity(
              opacity: canWrite ? 1.0 : 0.4,
              child: const Icon(Icons.emoji_emotions, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: canWrite,
              onChanged: (v) {
                _setTyping(true);
                _typingTimer?.cancel();
                _typingTimer = Timer(
                  const Duration(seconds: 1),
                  () => _setTyping(false),
                );
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Écrire...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: canWrite ? _sendMessage : null,
            child: Opacity(
              opacity: canWrite ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _header(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: color,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _activite!.titre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              try {
                openActiviteFicheModal(context, _activite!.id);
              } catch (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActiviteFichePage(activiteId: _activite!.id),
                  ),
                );
              }
            },
            icon: const Icon(Icons.event, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BULLES DE MESSAGES
  // ---------------------------------------------------------------------------
  Widget _messageBubble({
  required String messageId,
  required String prenom,
  required String photo,
  required String? text,
  required String? imageUrl,
  required String? gifUrl,
  required Map<String, dynamic>? location,
  required List<dynamic>? reactions,
  required Map<String, dynamic>? replyTo,
  required bool isMe,
  required bool isCreator,
  required DateTime? date,
  required Color color,
  }) {
  final Color bubbleColor =
      isMe ? Colors.white : Colors.white.withOpacity(0.9);

  final hasText = text != null && text.isNotEmpty;
  final hasImage = imageUrl != null && imageUrl.isNotEmpty;
  final hasGif = gifUrl != null && gifUrl.isNotEmpty;
  final hasLocation = location != null;

  return Container(
    key: ValueKey(messageId),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 22,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),

        if (!isMe) const SizedBox(width: 10),

        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    prenom.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isCreator)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "ORGANISATEUR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMe
                        ? Colors.black.withOpacity(0.08)
                        : color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (replyTo != null &&
                        (replyTo["preview"] ?? "").toString().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 30,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                replyTo["preview"].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasText)
                      Text(
                        text!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),

                    if (hasImage) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl!,
                          width: 230,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    if (hasGif) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          gifUrl!,
                          width: 230,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    if (hasLocation &&
                        location!["lat"] != null &&
                        location["lng"] != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final lat = location["lat"];
                          final lng = location["lng"];
                          final url =
                              "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
                          launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            "https://maps.googleapis.com/maps/api/staticmap?center=${location["lat"]},${location["lng"]}&zoom=16&size=400x250&markers=color:red%7C${location["lat"]},${location["lng"]}&key=$GOOGLE_STATIC_MAPS_KEY",
                            width: 230,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],

                    if (date != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _openMessageActionsModal(
                                messageId: messageId,
                                isMe: isMe,
                                text: text,
                                imageUrl: imageUrl,
                                gifUrl: gifUrl,
                                location: location,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.more_horiz,
                                  size: 14, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat("dd/MM HH:mm").format(date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (reactions != null && reactions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: _buildReactionWidgets(reactions),
                ),
              ],
            ],
          ),
        ),
      ],
    ));
  }

// ---------------------------------------------------------------------------
// REACTIONS : Groupe les emojis + compteur
// ---------------------------------------------------------------------------
List<Widget> _buildReactionWidgets(List reactions) {
  final Map<String, int> count = {};

  for (final r in reactions) {
    count[r] = (count[r] ?? 0) + 1;
  }

  return count.entries.map((entry) {
    final emoji = entry.key;
    final n = entry.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$emoji $n",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }).toList();
}
}
