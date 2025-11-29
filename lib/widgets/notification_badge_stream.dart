import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationBadgeStream {
  static Stream<int> get unreadCount {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: uid)
        .where("read", isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
