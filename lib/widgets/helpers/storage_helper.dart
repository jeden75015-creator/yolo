// lib/widgets/helpers/storage_helper.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolo/event/event_model.dart';

class StorageHelper {
  // ---------------------------------------------------------------------------
  //  🔥 Convertisseur gs:// → URL Firebase HTTPS
  // ---------------------------------------------------------------------------
  static String convert(String url) {
    if (!url.startsWith("gs://")) return url;

    final base = url.replaceFirst("gs://", "");
    final slash = base.indexOf("/");

    if (slash == -1) return url;

    final bucket = base.substring(0, slash);
    final path = Uri.encodeComponent(base.substring(slash + 1));

    return "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$path?alt=media";
  }

  // ---------------------------------------------------------------------------
  //  ❤️ FAVORIS : enregistrement local + auto-clean si endDate passée
  // ---------------------------------------------------------------------------
  static Future<List<EventModel>> getFavoris() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList("favoris") ?? [];

    DateTime now = DateTime.now();
    List<EventModel> validEvents = [];

    for (final item in jsonList) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final event = EventModel.fromJson(map);

      // ⚠ Auto-suppression si l’event est terminé
      if (event.endDate.isAfter(now)) {
        validEvents.add(event);
      }
    }

    // Mise à jour après nettoyage
    final cleaned = validEvents.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("favoris", cleaned);

    return validEvents;
  }

  static Future<void> addFavori(EventModel event) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList("favoris") ?? [];

    // éviter les doublons
    if (jsonList.any((e) => jsonDecode(e)["id"] == event.id)) return;

    jsonList.add(jsonEncode(event.toJson()));
    await prefs.setStringList("favoris", jsonList);
  }

  static Future<void> removeFavori(EventModel event) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList("favoris") ?? [];

    jsonList.removeWhere((e) => jsonDecode(e)["id"] == event.id);

    await prefs.setStringList("favoris", jsonList);
  }

  // ---------------------------------------------------------------------------
  //  ⭐ FAVORIS : bool + toggle
  // ---------------------------------------------------------------------------
  static Future<bool> isFavorite(EventModel e) async {
    final favs = await getFavoris();
    return favs.any((f) => f.id == e.id);
  }

  static Future<void> toggle(EventModel e) async {
    final fav = await isFavorite(e);
    if (fav) {
      await removeFavori(e);
    } else {
      await addFavori(e);
    }
  }

  // ---------------------------------------------------------------------------
  //  📌 DEFAULT GROUP IMAGE
  // ---------------------------------------------------------------------------
  static String defaultGroup() {
    return convert(
      "gs://yolo-d90ce.firebasestorage.app/group_photos/default_group.png",
    );
  }
}
