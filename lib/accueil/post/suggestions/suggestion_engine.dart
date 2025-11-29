import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../activite/activite_model.dart';
import '../../../activite/activite_service.dart';
import '../../../profil/user_service.dart';

// 👉 Ajout obligatoire
import 'new_users_card.dart';

import 'friend_activity_card.dart';
import 'recommended_activity_card.dart';
import 'region_new_activity_card.dart';


class SuggestionEngine {
  static Future<List<Widget>> generate({
    required List<Activite> activities,
  }) async {
    final List<Widget> suggestions = [];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return suggestions;

    final uid = user.uid;
    final userService = UserService();

    // 1️⃣ Amis participant à une activité
    final friends = await userService.getUserFriends(uid);

    final friendActivities = activities.where((a) {
      return a.participants.any((p) => friends.contains(p));
    }).toList();

    if (friendActivities.isNotEmpty) {
      final activity = friendActivities.first;

      final friendNames = <String>[];
      for (final id in activity.participants) {
        if (friends.contains(id)) {
          friendNames.add(await userService.getUserName(id));
        }
      }

      if (friendNames.isNotEmpty) {
        suggestions.add(FriendActivityNotificationCard(
          friendNames: friendNames,
          activite: activity,
        ));
      }
    }

    // 2️⃣ Nouvelle activité proche
    final nearby = activities.isNotEmpty ? activities.first : null;
    if (nearby != null) {
      suggestions.add(NewActivityNearbyCard(activite: nearby));
    }

    // 3️⃣ Recommandée
    final recommended =
        activities.isNotEmpty ? activities.last : null;
    if (recommended != null) {
      suggestions.add(RecommendedActivityCard(activite: recommended));
    }

    // 4️⃣ Nouveaux utilisateurs
    final newUsers = await userService.getNewUsersLite(limit: 10);
    if (newUsers.isNotEmpty) {
      suggestions.add(NewUsersCard(newUsers: newUsers));
    }

    return suggestions;
  }
}
