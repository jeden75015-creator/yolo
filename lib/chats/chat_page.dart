import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const String TENOR_API_KEY = "AIzaSyDSz2OEbEyLz02OKQ5imsw3Q0u1z3v2qWY";
const String GOOGLE_STATIC_MAPS_KEY = "AIzaSyBfm6IoyNEj8mCtnMCjOy-dsOELJt0efpk";

class ChatPage extends StatefulWidget {
  final String? conversationId; // null = conversation à créer
  final String otherUserId; // toujours requis

  const ChatPage({
    super.key,
    required this.otherUserId,
    this.conversationId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  String? _currentConversationId;
  bool _initialLoadDone = false;

  // 🔥 Réponse (aperçu local, pas dans Firestore)
  Map<String, dynamic>? _replyingTo;

  // 🔥 Édition
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    if (_currentConversationId != null) {
      _markMessagesAsRead();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // 🔥 SCROLL AUTO vers le bas (reverse: true → offset 0)
  // -------------------------------------------------------
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // -------------------------------------------------------
  // 🔥 CREATION AUTOMATIQUE DE LA CONVERSATION
  // -------------------------------------------------------
  Future<void> _ensureConversationExists() async {
    if (_currentConversationId != null) return;

    final newDoc =
        FirebaseFirestore.instance.collection("conversations").doc();

    _currentConversationId = newDoc.id;

    await newDoc.set({
      'users': [user.uid, widget.otherUserId],
      'lastMessage': '',
      'lastTime': FieldValue.serverTimestamp(),
      'unreadBy': [widget.otherUserId],
    });

    setState(() {});
  }

  // -------------------------------------------------------
  // 🔥 ENVOI / EDITION MESSAGE (texte + image + reply)
  // -------------------------------------------------------
  Future<void> _sendMessage({String? imageUrl}) async {
    final text = messageController.text.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (text.isEmpty && !hasImage) return;

    await _ensureConversationExists();

    final convoRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(_currentConversationId);

    // ✏️ MODE ÉDITION (texte uniquement)
    if (_editingMessageId != null && !hasImage) {
      await convoRef
          .collection("messages")
          .doc(_editingMessageId)
          .update({'text': text});

      setState(() {
        _editingMessageId = null;
        _replyingTo = null;
      });

      messageController.clear();
      _scrollToBottom();
      return;
    }

    // ✉️ NOUVEAU MESSAGE
    final Map<String, dynamic> data = {
      'senderId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'text': text,
      'imageUrl': imageUrl ?? '',
      'gifUrl': '',
    };

    // 🔁 Réponse enrichie : texte + image + gif + localisation
    if (_replyingTo != null) {
      final replyText = _replyingTo!['text'] as String?;
      final replyImage = _replyingTo!['imageUrl'] as String?;
      final replyGif = _replyingTo!['gifUrl'] as String?;
      final replyLoc = _replyingTo!['location'] as Map<String, dynamic>?;

      if (replyText != null && replyText.trim().isNotEmpty) {
        data['replyToText'] = replyText;
      }
      if (replyImage != null && replyImage.isNotEmpty) {
        data['replyToImageUrl'] = replyImage;
      }
      if (replyGif != null && replyGif.isNotEmpty) {
        data['replyToGifUrl'] = replyGif;
      }
      if (replyLoc != null) {
        data['replyToLocation'] = replyLoc;
      }
    }

    await convoRef.collection("messages").add(data);

    await convoRef.update({
      'lastMessage': text.isNotEmpty
          ? text
          : hasImage
              ? "📸 Photo"
              : "Message",
      'lastTime': FieldValue.serverTimestamp(),
      'lastSenderId': user.uid,
      'unreadBy': FieldValue.arrayUnion([widget.otherUserId]),
    });

    setState(() {
      _replyingTo = null;
      _editingMessageId = null;
    });

    messageController.clear();
    _scrollToBottom();
  }

  // -------------------------------------------------------
  // 📷 ENVOI IMAGE
  // -------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child("chat_images")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes);
    } else {
      await ref.putFile(File(picked.path));
    }

    final url = await ref.getDownloadURL();
    await _sendMessage(imageUrl: url);
  }

  // -------------------------------------------------------
  // 📍 ENVOI LOCALISATION
  // -------------------------------------------------------
  Future<void> _sendLocation() async {
    await _ensureConversationExists();

    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Active la localisation pour partager ta position."),
          ),
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
            content: Text("Permission localisation refusée en permanence."),
          ),
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


      final convoRef = FirebaseFirestore.instance
          .collection("conversations")
          .doc(_currentConversationId);

      final Map<String, dynamic> data = {
        'senderId': user.uid,
        'text': '',
        'imageUrl': '',
        'gifUrl': '',
        'location': {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'address': "Localisation",
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // 🔁 Réponse possible sur une localisation aussi
      if (_replyingTo != null) {
        final replyText = _replyingTo!['text'] as String?;
        final replyImage = _replyingTo!['imageUrl'] as String?;
        final replyGif = _replyingTo!['gifUrl'] as String?;
        final replyLoc = _replyingTo!['location'] as Map<String, dynamic>?;

        if (replyText != null && replyText.trim().isNotEmpty) {
          data['replyToText'] = replyText;
        }
        if (replyImage != null && replyImage.isNotEmpty) {
          data['replyToImageUrl'] = replyImage;
        }
        if (replyGif != null && replyGif.isNotEmpty) {
          data['replyToGifUrl'] = replyGif;
        }
        if (replyLoc != null) {
          data['replyToLocation'] = replyLoc;
        }
      }

      await convoRef.collection("messages").add(data);

      await convoRef.update({
        'lastMessage': "📍 Localisation partagée",
        'lastTime': FieldValue.serverTimestamp(),
        'lastSenderId': user.uid,
        'unreadBy': FieldValue.arrayUnion([widget.otherUserId]),
      });

      setState(() {
        _replyingTo = null;
        _editingMessageId = null;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("🔥 ERREUR ENVOI LOCALISATION : $e");
    }
  }

  // -------------------------------------------------------
  // 🕒 FORMAT DATE
  // -------------------------------------------------------
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final isToday =
        now.year == date.year &&
            now.month == date.month &&
            now.day == date.day;

    return isToday
        ? "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
        : "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // -------------------------------------------------------
  // 📥 MARQUER LUS
  // -------------------------------------------------------
  Future<void> _markMessagesAsRead() async {
    if (_currentConversationId == null) return;

    final convoRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(_currentConversationId);

    convoRef.update({
      "unreadBy": FieldValue.arrayRemove([user.uid])
    });

    final msgs = await convoRef.collection("messages").get();
    for (var doc in msgs.docs) {
      if (doc["senderId"] != user.uid && doc["isRead"] == false) {
        doc.reference.update({"isRead": true});
      }
    }
  }

  // -------------------------------------------------------
  // 🗑️ SUPPRESSION MESSAGE
  // -------------------------------------------------------
  Future<void> _deleteMessage(String id) async {
    if (_currentConversationId == null) return;

    final ref = FirebaseFirestore.instance
        .collection("conversations")
        .doc(_currentConversationId)
        .collection("messages")
        .doc(id);

    final snap = await ref.get();
    final data = snap.data();

    if (data != null && data["imageUrl"] != "") {
      try {
        await FirebaseStorage.instance.refFromURL(data["imageUrl"]).delete();
      } catch (_) {}
    }

    await ref.delete();
  }

  // -------------------------------------------------------
  // 🖼️ IMAGE / MAP FULLSCREEN
  // -------------------------------------------------------
  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(child: Image.network(imageUrl)),
          ),
        ),
      ),
    );
  }

  void _openMap(double lat, double lng) {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // -------------------------------------------------------
  // REACTIONS : coller une émotion (en dehors de la bulle)
  // -------------------------------------------------------
  Future<void> _addReactionToMessage(String messageId, String emoji) async {
    if (_currentConversationId == null) return;

    try {
      final ref = FirebaseFirestore.instance
          .collection("conversations")
          .doc(_currentConversationId)
          .collection("messages")
          .doc(messageId);

      await ref.set(
        {
          "reactions": FieldValue.arrayUnion([emoji]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("🔥 ERREUR AJOUT RÉACTION : $e");
    }
  }

  // -------------------------------------------------------
  // MENU D'ACTIONS POUR UN MESSAGE
  // -------------------------------------------------------
  void _openMessageActionsModal({
    required String messageId,
    required bool isMe,
    required String? text,
    required String? imageUrl,
    required String? gifUrl,
    required Map<String, dynamic>? location,
  }) {
    final canEdit = isMe &&
        (text != null && text.trim().isNotEmpty) &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (gifUrl == null || gifUrl.isEmpty) &&
        (location == null);

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
              // Ligne d'émotions façon WhatsApp
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in const ["❤️", "😂", "👍", "😮", "😢", "😡"])
                      GestureDetector(
                        onTap: () async {
                          await _addReactionToMessage(messageId, emoji);
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

              // Répondre (sur texte + image + GIF + localisation)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text("Répondre"),
                onTap: () {
                  setState(() {
                    _replyingTo = {
                      "msgId": messageId,
                      "text": text,
                      "imageUrl": imageUrl,
                      "gifUrl": gifUrl,
                      "location": location,
                    };
                    _editingMessageId = null;
                  });
                  Navigator.pop(context);
                },
              ),

              // Copier
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copier"),
                onTap: () async {
                  if (text != null && text.trim().isNotEmpty) {
                    try {
                      await Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Message copié"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Clipboard error: $e");
                    }
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
                      messageController.text = text;
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
                    await _deleteMessage(messageId);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------
  // ENVOYER UN GIF
  // -------------------------------------------------------
  Future<void> _sendGif(String gifUrl) async {
    await _ensureConversationExists();

    final convoRef = FirebaseFirestore.instance
        .collection("conversations")
        .doc(_currentConversationId);

    final Map<String, dynamic> data = {
      'senderId': user.uid,
      'text': '',
      'imageUrl': '',
      'gifUrl': gifUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // 🔁 Réponse possible sur un GIF
    if (_replyingTo != null) {
      final replyText = _replyingTo!['text'] as String?;
      final replyImage = _replyingTo!['imageUrl'] as String?;
      final replyGif = _replyingTo!['gifUrl'] as String?;
      final replyLoc = _replyingTo!['location'] as Map<String, dynamic>?;

      if (replyText != null && replyText.trim().isNotEmpty) {
        data['replyToText'] = replyText;
      }
      if (replyImage != null && replyImage.isNotEmpty) {
        data['replyToImageUrl'] = replyImage;
      }
      if (replyGif != null && replyGif.isNotEmpty) {
        data['replyToGifUrl'] = replyGif;
      }
      if (replyLoc != null) {
        data['replyToLocation'] = replyLoc;
      }
    }

    await convoRef.collection("messages").add(data);

    await convoRef.update({
      'lastMessage': "GIF envoyé",
      'lastTime': FieldValue.serverTimestamp(),
      'lastSenderId': user.uid,
      'unreadBy': FieldValue.arrayUnion([widget.otherUserId]),
    });

    setState(() {
      _replyingTo = null;
      _editingMessageId = null;
    });

    _scrollToBottom();
  }

  // -------------------------------------------------------
  // OUVRIR LE PICKER TENOR (barre de recherche corrigée)
  // -------------------------------------------------------
  Future<void> _openGifPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return _gifPickerModal(ctx);
      },
    );
  }

  Widget _gifPickerModal(BuildContext bottomSheetContext) {
    final TextEditingController searchCtrl = TextEditingController();
    List gifs = [];
    bool isLoading = true;

    Future<void> loadGifs(String q, void Function(void Function()) setState) async {
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
          setState(() {
            gifs = data["results"] ?? [];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        debugPrint("🔥 ERREUR TENOR : $e");
        setState(() => isLoading = false);
      }
    }

    return SafeArea(
      child: StatefulBuilder(
        builder: (context, setState) {
          if (isLoading && gifs.isEmpty) {
            // Premier chargement : trending
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadGifs("", setState);
            });
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
                    setState(() => isLoading = true);
                    loadGifs(v.trim(), setState);
                  },
                ),
                const SizedBox(height: 10),
                if (isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
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
  // -------------------------------------------------------
  // 🔥 BUBBLE MESSAGE
  // -------------------------------------------------------
  Widget _buildMessageTile(QueryDocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    final isMe = m["senderId"] == user.uid;

    final text = (m["text"] ?? "").toString();
    final hasText = text.isNotEmpty;

    final imageUrl = (m["imageUrl"] ?? "").toString();
    final hasImage = imageUrl.isNotEmpty;

    final gifUrl = (m["gifUrl"] ?? "").toString();
    final hasGif = gifUrl.isNotEmpty;

    final locationMapRaw = m["location"];
    Map<String, dynamic>? location;
    bool hasLocation = false;
    if (locationMapRaw != null && locationMapRaw is Map) {
      location = Map<String, dynamic>.from(locationMapRaw);
      hasLocation = location["lat"] != null && location["lng"] != null;
    }

    // 🔁 Reply visual
    final replyText = (m["replyToText"] ?? "").toString();
    final replyImageUrl = (m["replyToImageUrl"] ?? "").toString();
    final replyGifUrl = (m["replyToGifUrl"] ?? "").toString();
    final replyLocRaw = m["replyToLocation"];
    Map<String, dynamic>? replyLocation;
    bool hasReplyLocation = false;
    if (replyLocRaw != null && replyLocRaw is Map) {
      replyLocation = Map<String, dynamic>.from(replyLocRaw);
      hasReplyLocation =
          replyLocation["lat"] != null && replyLocation["lng"] != null;
    }

    final hasReply = replyText.isNotEmpty ||
        replyImageUrl.isNotEmpty ||
        replyGifUrl.isNotEmpty ||
        hasReplyLocation;

    final ts = m["createdAt"] as Timestamp?;
    final reactions = m["reactions"] as List<dynamic>?;

    final bubbleColor =
        isMe ? const Color(0xFFFFB347) : Colors.white.withOpacity(0.9);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟣 Bloc de réponse translucide
                    if (hasReply)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (replyText.isNotEmpty)
                              Text(
                                replyText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.black.withOpacity(0.9)
                                      : Colors.black87,
                                ),
                              ),
                            if (replyImageUrl.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  replyImageUrl,
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            if (replyGifUrl.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  replyGifUrl,
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            if (hasReplyLocation && replyLocation != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.redAccent),
                                  SizedBox(width: 4),
                                  Text(
                                    "Localisation",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    if (hasImage)
                      GestureDetector(
                        onTap: () => _showFullImage(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    if (hasGif) ...[
                      if (hasImage || hasText || hasLocation) const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          gifUrl,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    if (hasLocation && location != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openMap(
                            (location?["lat"] as num).toDouble(),
                            (location?["lng"] as num).toDouble()),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            "https://maps.googleapis.com/maps/api/staticmap?center=${location["lat"]},${location["lng"]}&zoom=16&size=400x250&markers=color:red%7C${location["lat"]},${location["lng"]}&key=$GOOGLE_STATIC_MAPS_KEY",
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],

                    if (hasText)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),

                    if (ts != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Petite bulle grise : flèche + emoji neutre
                          GestureDetector(
                            onTap: () {
                              _openMessageActionsModal(
                                messageId: doc.id,
                                isMe: isMe,
                                text: text.isEmpty ? null : text,
                                imageUrl: hasImage ? imageUrl : null,
                                gifUrl: hasGif ? gifUrl : null,
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.arrow_drop_down,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Icon(Icons.sentiment_neutral,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimestamp(ts),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Réactions EN DEHORS de la bulle
          if (reactions != null && reactions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: reactions
                  .map<Widget>(
                    (r) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        r.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // 🔥 BARRE REPLY / EDIT AU-DESSUS DE L'INPUT
  // -------------------------------------------------------
  Widget _buildReplyOrEditBar() {
    if (_editingMessageId == null && _replyingTo == null) {
      return const SizedBox.shrink();
    }

    String label;
    String content = "";
    String? icon;

    if (_editingMessageId != null) {
      label = "Modification du message";
      content = messageController.text;
    } else {
      label = "Répondre à ce message";
      final t = (_replyingTo?["text"] ?? "").toString();
      final img = (_replyingTo?["imageUrl"] ?? "").toString();
      final gif = (_replyingTo?["gifUrl"] ?? "").toString();
      final loc = _replyingTo?["location"] as Map<String, dynamic>?;

      if (t.isNotEmpty) {
        content = t;
      } else if (img.isNotEmpty) {
        content = "Photo";
        icon = "📸";
      } else if (gif.isNotEmpty) {
        content = "GIF";
        icon = "🎬";
      } else if (loc != null) {
        content = "Localisation";
        icon = "📍";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withOpacity(0.9),
        border: const Border(
          top: BorderSide(color: Colors.grey),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
          ],
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
  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discussion"),
        backgroundColor: const Color(0xFFFF7043),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFBEB),
              Color(0xFFFFF1F2),
              Color(0xFFEEF2FF)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // ---------------------------------------------------
            // 🔥 ZONE MESSAGES
            // ---------------------------------------------------
            Expanded(
              child: _currentConversationId == null
                  ? const Center(
                      child: Text(
                        "Commence la conversation 👋",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("conversations")
                          .doc(_currentConversationId)
                          .collection("messages")
                          .orderBy("createdAt", descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          );
                        }

                        if (!_initialLoadDone) {
                          _initialLoadDone = true;
                          _markMessagesAsRead();
                        }

                        final msgs = snap.data!.docs;

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: msgs.length,
                          itemBuilder: (context, i) {
                            return _buildMessageTile(msgs[i]);
                          },
                        );
                      },
                    ),
            ),

            // Barre Reply / Edit
            _buildReplyOrEditBar(),

            // ---------------------------------------------------
            // ✍️ CHAMP D'ÉCRITURE
            // ---------------------------------------------------
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo, color: Color(0xFFFF7043)),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on,
                        color: Color(0xFFFF7043)),
                    onPressed: _sendLocation,
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions,
                        color: Color(0xFFFF7043)),
                    onPressed: _openGifPicker,
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Écrire un message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFFF7043)),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
