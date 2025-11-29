import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'groupe_edit_page.dart';
import 'groupe_model.dart';
import 'groupe_service.dart';
import 'members_list_page.dart';
import 'package:yolo/profil/profil.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';

// pour le bouton "Créer"
import '../accueil/modal_post.dart';
import '../activite/activite_creation_page.dart';

const String TENOR_API_KEY = "AIzaSyDSz2OEbEyLz02OKQ5imsw3Q0u1z3v2qWY";
const String GOOGLE_STATIC_MAPS_KEY = "AIzaSyBfm6IoyNEj8mCtnMCjOy-dsOELJt0efpk";

class GroupeChatPage extends StatefulWidget {
  final String groupeId;

  const GroupeChatPage({super.key, required this.groupeId});

  @override
  State<GroupeChatPage> createState() => _GroupeChatPageState();
}

class _GroupeChatPageState extends State<GroupeChatPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final GroupeService service = GroupeService();

  GroupeModel? groupe;
  bool isAdmin = false;

  // stream groupe
  StreamSubscription<GroupeModel>? _groupSub;

  // Reply
  Map<String, dynamic>? _replyingTo;

  // Edit
  String? _editingMessageId;

  // Drawer infos
  bool _drawerOpen = false;

  // Notifications ON/OFF
  bool _notifEnabled = true;
  bool _notifLoading = false;

  bool get _isAdminOrCreator {
    if (groupe == null) return false;
    return isAdmin || groupe!.createurId == user.uid;
  }

  /// Helper pour éviter tous les `setState()` après `dispose()`.
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();

    // Écoute live du groupe + marquage lu
    _groupSub = service
        .listenGroup(widget.groupeId)
        .listen(
          (g) {
            if (!mounted) return;
            safeSetState(() {
              groupe = g;
              isAdmin = g.admins.contains(user.uid);
            });
            // marquage lu
            service.markGroupAsRead(widget.groupeId);
          },
          onError: (error) {
            _groupSub?.cancel();
          },
        );

    _loadNotifSettings();
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    messageController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _autoScroll() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "";
    final d = ts.toDate();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return "${d.day}/${d.month} $hh:$mm";
  }

  // -------------------------------------------------------
  // 🔥 Résolution universelle de la couleur
  // -------------------------------------------------------
  Color _resolveColor(dynamic raw) {
    try {
      if (raw == null) return Colors.deepPurple;

      if (raw is int) return Color(raw);

      final v = raw.toString().trim();

      if (v.startsWith("#")) {
        return Color(int.parse(v.replaceFirst("#", "0xff")));
      }

      if (v.startsWith("0x")) {
        return Color(int.parse(v));
      }

      return Color(int.parse(v));
    } catch (_) {
      return Colors.deepPurple;
    }
  }

  // ============================================================
  // 🔔 NOTIFICATIONS – LECTURE / TOGGLE
  // ============================================================

  Future<void> _loadNotifSettings() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("notificationSettings")
          .doc("group_${widget.groupeId}");

      final snap = await ref.get();
      if (!mounted) return;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        safeSetState(() {
          _notifEnabled = (data["enabled"] as bool?) ?? true;
        });
      }
    } catch (_) {
      // on ne casse pas l'écran pour ça
    }
  }

  Future<void> _toggleNotif() async {
    if (groupe == null) return;

    safeSetState(() => _notifLoading = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("notificationSettings")
          .doc("group_${widget.groupeId}");

      final newValue = !_notifEnabled;

      await ref.set({
        "enabled": newValue,
        "groupId": widget.groupeId,
        "type": "group",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      safeSetState(() {
        _notifEnabled = newValue;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de la mise à jour des notifications."),
          ),
        );
      }
    } finally {
      safeSetState(() => _notifLoading = false);
    }
  }


  void _shareGroupLink() async {
    if (groupe == null) return;

    final link = "https://yolo.app/group/${groupe!.id}";
    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Lien d’invitation copié dans le presse-papier ✨"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // 🔥 HEADER
  // ============================================================

  Widget _buildHeader() {
    if (groupe == null) return const SizedBox(height: 60);

    final color1 = _resolveColor(groupe!.couleur);
    final color2 = _resolveColor(groupe!.couleur).withOpacity(0.7);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color1, color2]),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: groupe!.photoUrl.isNotEmpty
                            ? NetworkImage(groupe!.photoUrl)
                            : null,
                        child: groupe!.photoUrl.isEmpty
                            ? const Icon(Icons.groups, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          groupe!.nom.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final res = await showModalPostSelector(context);
                    if (res == null) return;

                    if (res == "post") {
                      if (!mounted) return;
                      Navigator.pushNamed(context, "/create_post");
                    } else if (res == "poll") {
                      if (!mounted) return;
                      Navigator.pushNamed(context, "/create_poll");
                    } else if (res == "activite") {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActiviteCreationPage(),
                        ),
                      );
                    } else if (res == "groupe") {
                      if (!mounted) return;
                      Navigator.pushNamed(context, "/create_group");
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Créer",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Languette
        GestureDetector(
          onTap: () => safeSetState(() => _drawerOpen = !_drawerOpen),
          child: Container(
            height: 28,
            width: double.infinity,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _drawerOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Infos du groupe",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),

        _buildGroupDrawer(),
      ],
    );
  }

  // ============================================================
  // 🔥 TIROIR — RESPONSIVE
  // ============================================================

  Widget _buildGroupDrawer() {
    if (groupe == null) return const SizedBox();

    final maxHeight = MediaQuery.of(context).size.height * 0.60;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      width: double.infinity,
      height: _drawerOpen ? maxHeight : 0,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: _drawerContent(),
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 CONTENU DU TIROIR
  // ============================================================

  Widget _drawerContent() {
    if (groupe == null) return const SizedBox();

    final isCreator = groupe!.createurId == user.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: groupe!.photoUrl.isNotEmpty
                  ? NetworkImage(groupe!.photoUrl)
                  : null,
              child: groupe!.photoUrl.isEmpty
                  ? const Icon(Icons.groups, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                groupe!.description.isEmpty
                    ? "Aucune description."
                    : groupe!.description,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.verified_user, size: 20, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(
              isCreator
                  ? "Rôle : Créateur"
                  : isAdmin
                  ? "Rôle : Admin"
                  : "Rôle : Membre",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.people, color: Colors.blueAccent),
          title: Text(
            "Voir les ${groupe!.membres.length} membres",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MembersListPage(groupe: groupe!),
              ),
            );
          },
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.share, color: Colors.green),
          title: const Text("Inviter un ami"),
          onTap: _shareGroupLink,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Notifications"),
          value: _notifEnabled,
          secondary: const Icon(
            Icons.notifications_active,
            color: Colors.orange,
          ),
          onChanged: _notifLoading ? null : (v) => _toggleNotif(),
        ),
        if (isAdmin || isCreator)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit, color: Colors.deepPurple),
            title: const Text("Modifier le groupe"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupeEditPage(groupe: groupe!),
                ),
              );
            },
          ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text("Quitter le groupe"),
          onTap: () async {
            await service.quitterGroupe(widget.groupeId);
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // ============================================================
  // 🔥 REPLY / EDIT BAR
  // ============================================================

  Widget _buildReplyOrEditBar() {
    if (_editingMessageId == null && _replyingTo == null) {
      return const SizedBox.shrink();
    }

    String label;
    String content;

    if (_editingMessageId != null) {
      label = "Modification du message";
      content = messageController.text;
    } else {
      label = "Répondre à ce message";
      content = (_replyingTo?["preview"] ?? "").toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: const Border(top: BorderSide(color: Colors.grey)),
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
              safeSetState(() {
                _editingMessageId = null;
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 BADGE RÔLE (Admin / Créateur)
  // ============================================================

  Widget _roleChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 BUBBLE MESSAGE
  // ============================================================

  Widget _buildMessageTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String senderId = data["senderId"] ?? data["userId"] ?? "";
    final String text = (data["text"] ?? data["message"] ?? "").toString();
    final String? img = (data["imageUrl"] ?? "") as String?;
    final String? gifUrl = (data["gifUrl"] ?? "") as String?;
    final Map<String, dynamic>? location = data["location"] != null
        ? Map<String, dynamic>.from(data["location"])
        : null;

    final Timestamp? ts = data["createdAt"] as Timestamp?;
    final String timeStr = _formatTimestamp(ts);

    final bool isMe = senderId == user.uid;

    // 🔥 RÉACTIONS
    final List<dynamic> reactionsRaw = (data["reactions"] is List)
        ? List<dynamic>.from(data["reactions"])
        : [];

    final replyToRaw = data["replyTo"];
    Map<String, dynamic>? replyTo;
    if (replyToRaw != null && replyToRaw is Map) {
      replyTo = Map<String, dynamic>.from(replyToRaw);
    }
    String replyPreview = "";
    if (replyTo != null) {
      if (replyTo["preview"] != null) {
        replyPreview = replyTo["preview"].toString();
      } else if (replyTo["text"] != null) {
        replyPreview = replyTo["text"].toString();
      }
    }

    final bool isCreator = groupe != null && groupe!.createurId == senderId;
    final bool isAdminUser =
        groupe != null && groupe!.admins.contains(senderId);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(senderId)
          .get(),
      builder: (_, snapUser) {
        if (!snapUser.hasData || !snapUser.data!.exists) {
          return const SizedBox();
        }

        final u = snapUser.data!.data() as Map<String, dynamic>;
        final prenom = u["firstName"] ?? "Profil";
        final photo = u["photoUrl"] ?? "";

        final Color bubbleColor = isMe ? Colors.orange.shade300 : Colors.white;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: senderId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: photo.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Text(
                          prenom.toUpperCase(),
                          style: TextStyle(
                            color: isMe ? Colors.deepPurple : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (isCreator) _roleChip("Créateur", Colors.orange),
                        if (!isCreator && isAdminUser)
                          _roleChip("Admin", Colors.deepPurple),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (replyPreview.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.1),
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
                                      replyPreview,
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
                          if (text.isNotEmpty)
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          if (img != null && img.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                img,
                                width: 230,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          if (gifUrl != null && gifUrl.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                gifUrl,
                                width: 230,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          if (location != null &&
                              location["lat"] != null &&
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
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  "https://maps.googleapis.com/maps/api/staticmap?center=${location["lat"]},${location["lng"]}&zoom=16&size=400x250&markers=color:red%7C${location["lat"]},${location["lng"]}&key=$GOOGLE_STATIC_MAPS_KEY",
                                  width: 230,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                          if (timeStr.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _openMessageActionsModal(
                                      msgId: doc.id,
                                      isMine: isMe,
                                      senderId: senderId,
                                      text: text,
                                      img: img,
                                      gifUrl: gifUrl,
                                      location: location,
                                      reactions: reactionsRaw,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.more_horiz,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (reactionsRaw.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: _buildReactionWidgets(reactionsRaw),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 🔥 REACTIONS – Groupement & compteur (même logique qu’ActiviteChat)
  // ============================================================
  List<Widget> _buildReactionWidgets(List<dynamic> reactions) {
    final Map<String, int> count = {};

    for (final r in reactions) {
      final key = r.toString();
      count[key] = (count[key] ?? 0) + 1;
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
        child: Text("$emoji $n", style: const TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  // ============================================================
  // 🔥 ACTIONS SUR MESSAGE
  // ============================================================

  void _openMessageActionsModal({
    required String msgId,
    required bool isMine,
    required String senderId,
    required String? text,
    required String? img,
    required String? gifUrl,
    required Map<String, dynamic>? location,
    required List<dynamic>? reactions,
  }) {
    final bool hasText = text != null && text.trim().isNotEmpty;
    final bool hasImage = img != null && img.trim().isNotEmpty;
    final bool hasGif = gifUrl != null && gifUrl.trim().isNotEmpty;
    final bool hasLocation = location != null;

    final bool canEdit =
        isMine && hasText && !hasImage && !hasGif && !hasLocation;

    String buildPreview() {
      if (hasText) {
        final s = text.trim();
        return s.length > 70 ? "${s.substring(0, 70)}…" : s;
      }
      if (hasImage) return "📸 Photo";
      if (hasGif) return "GIF";
      if (hasLocation) return "📍 Localisation";
      return "Message";
    }

    Future<void> _reportUser() async {
      if (groupe == null) return;
      try {
        await service.signalerMembre(groupe!.id, senderId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signalement envoyé"),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du signalement"),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
              // emojis
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in const [
                      "❤️",
                      "😂",
                      "👍",
                      "😮",
                      "😢",
                      "😡",
                    ])
                      GestureDetector(
                        onTap: () async {
                          await _toggleReaction(msgId, emoji);
                          if (mounted) Navigator.pop(context);
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

              // Voir profil
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Voir le profil"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: senderId),
                    ),
                  );
                },
              ),

              // reply
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text("Répondre"),
                onTap: () {
                  safeSetState(() {
                    _replyingTo = {
                      "messageId": msgId,
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

              // copy
              if (hasText)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text("Copier"),
                  onTap: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Message copié"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (_) {}
                    if (mounted) Navigator.pop(context);
                  },
                ),

              // Signalement
              if (!isMine)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text("Signaler l’utilisateur"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _reportUser();
                  },
                ),

              // edit
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Modifier"),
                  onTap: () {
                    safeSetState(() {
                      _editingMessageId = msgId;
                      messageController.text = text;
                      _replyingTo = null;
                    });
                    Navigator.pop(context);
                  },
                ),

              // delete
              if (isMine || _isAdminOrCreator)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Supprimer"),
                  onTap: () async {
                    await _deleteMessage(msgId, img, gifUrl);
                    if (mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 🔥 SUPPRESSION MESSAGE
  // ============================================================

  Future<void> _deleteMessage(String msgId, String? img, String? gifUrl) async {
    final ref = FirebaseFirestore.instance
        .collection("groupes")
        .doc(widget.groupeId)
        .collection("messages")
        .doc(msgId);

    if (img != null && img.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(img).delete();
      } catch (_) {}
    }

    if (gifUrl != null &&
        gifUrl.isNotEmpty &&
        gifUrl.startsWith("https://firebasestorage")) {
      try {
        await FirebaseStorage.instance.refFromURL(gifUrl).delete();
      } catch (_) {}
    }

    await ref.delete();
  }

  // ============================================================
  // 🔥 GIF / IMAGE / LOCATION / SEND / REACTIONS
  // ============================================================

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child("group_images")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    if (kIsWeb) {
      await ref.putData(await picked.readAsBytes());
    } else {
      await ref.putFile(File(picked.path));
    }

    final url = await ref.getDownloadURL();
    await _sendMessage(imageUrl: url);
  }

  /// 🔥 Toggle réaction – même logique que dans ActiviteChat
  Future<void> _toggleReaction(String msgId, String emoji) async {
    final ref = FirebaseFirestore.instance
        .collection("groupes")
        .doc(widget.groupeId)
        .collection("messages")
        .doc(msgId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> list = List<dynamic>.from(data["reactions"] ?? []);

      // On ajoute toujours l'emoji (tu peux avoir ❤️❤️😂 etc.)
      list.add(emoji);

      tx.update(ref, {"reactions": list});
    });
  }

  Future<void> _sendGif(String gifUrl) async {
    await _sendMessage(gifUrl: gifUrl);
  }

  Future<void> _sendLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _sendMessage(
        location: {
          "lat": pos.latitude,
          "lng": pos.longitude,
          "address": "Localisation",
        },
      );
    } catch (_) {}
  }

  Future<void> _sendMessage({
    String? imageUrl,
    String? gifUrl,
    Map<String, dynamic>? location,
  }) async {
    final text = messageController.text.trim();

    final bool hasText = text.isNotEmpty;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final bool hasGif = gifUrl != null && gifUrl.isNotEmpty;
    final bool hasLocation = location != null;

    if (!hasText && !hasImage && !hasGif && !hasLocation) return;

    final col = FirebaseFirestore.instance
        .collection("groupes")
        .doc(widget.groupeId)
        .collection("messages");

    // EDIT
    if (_editingMessageId != null && !hasImage && !hasGif && !hasLocation) {
      await col.doc(_editingMessageId).update({
        if (hasText) "text": text,
        if (!hasText) "text": FieldValue.delete(),
      });

      if (!mounted) return;
      safeSetState(() {
        _editingMessageId = null;
        _replyingTo = null;
      });

      messageController.clear();
      Future.delayed(const Duration(milliseconds: 120), _autoScroll);
      return;
    }

    // NOUVEAU MESSAGE
    final Map<String, dynamic> payload = {
      "senderId": user.uid,
      "createdAt": FieldValue.serverTimestamp(),
      "reactions": <String>[], // champ toujours présent
    };

    if (hasText) payload["text"] = text;
    if (hasImage) payload["imageUrl"] = imageUrl;
    if (hasGif) payload["gifUrl"] = gifUrl;
    if (hasLocation) payload["location"] = location;

    if (_replyingTo != null) {
      payload["replyTo"] = {
        "messageId": _replyingTo!["messageId"],
        "preview": _replyingTo!["preview"] ?? "",
        "hasImage": _replyingTo!["hasImage"] ?? false,
        "hasGif": _replyingTo!["hasGif"] ?? false,
        "hasLocation": _replyingTo!["hasLocation"] ?? false,
      };
    }

    await col.add(payload);

    String lastLabel = "Message";
    if (hasText) {
      lastLabel = text;
    } else if (hasImage) {
      lastLabel = "📸 Photo";
    } else if (hasGif) {
      lastLabel = "GIF envoyé";
    } else if (hasLocation) {
      lastLabel = "📍 Localisation partagée";
    }

    await service.updateLastMessage(widget.groupeId, lastLabel);

    if (!mounted) return;
    safeSetState(() {
      _replyingTo = null;
      _editingMessageId = null;
    });

    messageController.clear();
    Future.delayed(const Duration(milliseconds: 120), _autoScroll);
  }

  // ============================================================
  // 🔥 GIF PICKER
  // ============================================================

  Future<void> _openGifPicker() async {
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

    Future<void> loadGifs(
      String q,
      void Function(void Function()) sbSetState,
    ) async {
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
          final Map<String, dynamic> decoded = jsonDecode(res.body);
          gifs = decoded["results"] ?? [];
        }
      } catch (_) {}

      sbSetState(() {
        isLoading = false;
      });
    }

    return SafeArea(
      child: StatefulBuilder(
        builder: (context, sbSetState) {
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
                            child: Image.network(gifUrl, fit: BoxFit.cover),
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

  // ============================================================
  // 🔥 BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("groupes")
                  .doc(widget.groupeId)
                  .collection("messages")
                  .orderBy("createdAt")
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snap.data!.docs;
                _autoScroll();

                return ListView.builder(
                  controller: _scroll,
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _buildMessageTile(messages[i]),
                );
              },
            ),
          ),
          _buildReplyOrEditBar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.deepPurple),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.redAccent),
                  onPressed: _sendLocation,
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions, color: Colors.orange),
                  onPressed: _openGifPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Message…",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
