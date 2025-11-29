import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // ← IMPORTANT pour kIsWeb

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _users = FirebaseFirestore.instance.collection("users");
  final _notif = FirebaseFirestore.instance.collection("notifications");

  // ---------------------------------------------------------------------------
  // 🔥 INIT : Permission + enregistrement du token FCM (WEB SAFE)
  // ---------------------------------------------------------------------------
  Future<void> initAndRegisterToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🔐 Permissions FCM → uniquement mobile
    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {
        // On ignore en silence pour éviter "Unsupported operation"
      }
    }

    // 🎯 Récupération du token (Web peut retourner null)
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // Sur Web, si mal configuré, getToken peut planter → on ignore
      return;
    }

    if (token == null) {
      // FCM Web non configuré (push certificate VAPID manquant)
      return;
    }

    // Sauvegarde en Firestore
    await _users.doc(user.uid).update({
      "fcmToken": token,
    });

    // 🔄 Mise à jour automatique si le token change (OK Web + mobile)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _users.doc(user.uid).update({"fcmToken": newToken});
    });
  }

  // ---------------------------------------------------------------------------
  // 🔧 Vérif des préférences Firestore
  // ---------------------------------------------------------------------------
  Future<bool> _isEnabled(String userId, String field) async {
    final doc = await _users
        .doc(userId)
        .collection("notificationSettings")
        .doc("config")
        .get();

    final data = doc.data();

    if (data == null) return true;
    if (data["general"] == false) return false;

    return data[field] == true;
  }

  Future<void> _send({
    required String toUser,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? extra,
  }) async {
    final ok = await _isEnabled(toUser, type);
    if (!ok) return;

    await _notif.add({
      "userId": toUser,
      "toUserId": toUser,
      "title": title,
      "message": body,
      "type": type,
      "extra": extra ?? {},
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📌 TYPES DE NOTIFS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> sendLikePostNotification({
    required String postOwnerId,
    required String postId,
  }) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me == postOwnerId) return;

    await _send(
      toUser: postOwnerId,
      type: "likes",
      title: "Nouveau like 👍",
      body: "Quelqu'un a aimé votre publication.",
      extra: {"postId": postId},
    );
  }

  Future<void> sendCommentPostNotification({
    required String postOwnerId,
    required String postId,
    required String commentText,
  }) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me == postOwnerId) return;

    final short =
        commentText.length > 80 ? "${commentText.substring(0, 80)}…" : commentText;

    await _send(
      toUser: postOwnerId,
      type: "comments",
      title: "Nouveau commentaire 💬",
      body: short.isEmpty
          ? "Quelqu'un a commenté votre publication."
          : "« $short »",
      extra: {"postId": postId},
    );
  }

  Future<void> sendChatMessageNotification({
    required String toUserId,
    required String fromUserName,
    required String message,
  }) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me == toUserId) return;

    final short =
        message.length > 80 ? "${message.substring(0, 80)}…" : message;

    await _send(
      toUser: toUserId,
      type: "messages",
      title: "Nouveau message ✉️",
      body: "$fromUserName : $short",
    );
  }

  Future<void> sendActivityInviteNotification({
    required String toUserId,
    required String activityId,
    required String activityName,
  }) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me == toUserId) return;

    await _send(
      toUser: toUserId,
      type: "activityInvites",
      title: "Invitation à une activité 🎉",
      body: "Vous êtes invité à : $activityName",
      extra: {"activityId": activityId},
    );
  }

  Future<void> sendNewFriendNotification({
    required String toUserId,
    required String friendName,
  }) async {
    await _send(
      toUser: toUserId,
      type: "newFriends",
      title: "Nouvel ami 👥",
      body: "$friendName est maintenant dans votre réseau.",
    );
  }

  Future<void> sendNewUserAroundNotification({
    required String toUserId,
  }) async {
    await _send(
      toUser: toUserId,
      type: "newUsers",
      title: "Nouveau membre 🆕",
      body: "Un nouvel utilisateur a rejoint YOLO près de chez vous.",
    );
  }

  Future<void> sendSuggestionNotification({
    required String toUserId,
    String? suggestionType,
  }) async {
    await _send(
      toUser: toUserId,
      type: "suggestions",
      title: "Suggestion pour vous ⭐",
      body: "Un nouveau contenu pourrait vous plaire.",
      extra: {"kind": suggestionType ?? "generic"},
    );
  }

  Future<void> sendAppUpdateNotification({
    required String toUserId,
    String? title,
    String? body,
  }) async {
    await _send(
      toUser: toUserId,
      type: "appUpdates",
      title: title ?? "Nouvelle mise à jour YOLO",
      body: body ?? "Découvrez les dernières nouveautés de l'application.",
    );
  }
}
