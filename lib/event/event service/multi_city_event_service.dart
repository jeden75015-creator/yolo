// services/events/multi_city_event_service.dart
import 'package:yolo/event/event_model.dart';

// Tous les services individuels
import 'paris_event_service.dart';
import 'lille_event_service.dart';
import 'nantes_event_service.dart';
import 'lyon_event_service.dart';
import 'bordeaux_event_service.dart';
import 'toulouse_event_service.dart';
import 'marseille_event_service.dart';
import 'idf_event_service.dart';

class MultiCityEventService {
  final _paris = ParisEventService();
  final _lille = LilleEventService();
  final _nantes = NantesEventService();
  final _lyon = LyonEventService();
  final _bordeaux = BordeauxEventService();
  final _toulouse = ToulouseEventService();
  final _marseille = MarseilleEventService();
  final _idf = IDFEventService();

  /// Liste propre des villes supportées
  static const supportedCities = [
    "paris",
    "lille",
    "nantes",
    "lyon",
    "bordeaux",
    "toulouse",
    "marseille",
    "idf",
  ];

  // -----------------------
  // 🔥 FETCH SINGLE CITY
  // -----------------------
  Future<List<EventModel>> fetchCity(String city, {bool reset = false}) async {
    city = city.toLowerCase();

    switch (city) {
      case "paris":
        return _paris.fetchEvents(reset: reset);

      case "lille":
        return _lille.fetchEvents(reset: reset);

      case "nantes":
        return _nantes.fetchEvents();

      case "lyon":
        return _lyon.fetchEvents();

      case "bordeaux":
        return _bordeaux.fetchEvents();

      case "toulouse":
        return _toulouse.fetchEvents();

      case "marseille":
        return _marseille.fetchEvents();

      case "idf":
      case "iledefrance":
      case "ile-de-france":
        return _idf.fetchEvents();
    }

    throw Exception("Ville inconnue : $city");
  }

  // -----------------------
  // 🌍 FETCH ALL CITIES EN MÊME TEMPS
  // -----------------------
  Future<List<EventModel>> fetchAll({bool resetParis = false}) async {
    final futures = [
      _paris.fetchEvents(reset: resetParis),
      _lille.fetchEvents(),
      _nantes.fetchEvents(),
      _lyon.fetchEvents(),
      _bordeaux.fetchEvents(),
      _toulouse.fetchEvents(),
      _marseille.fetchEvents(),
      _idf.fetchEvents(),
    ];

    // 1️⃣ Appels simultanés
    final responses = await Future.wait(
      futures.map((f) => f.catchError((_) => <EventModel>[])),
    );

    // 2️⃣ Fusion
    final List<EventModel> all = responses.expand((e) => e).toList();

    // 3️⃣ Dedoublonnage par ID
    final Map<String, EventModel> unique = {};
    for (final e in all) {
      unique[e.id] = e;
    }

    // 4️⃣ Tri par date
    final sorted = unique.values.toList()
      ..sort((a, b) {
        final da = a.dateStart ?? DateTime.now();
        final db = b.dateStart ?? DateTime.now();
        return da.compareTo(db);
      });

    return sorted;
  }

  // -----------------------
  // 📌 FETCH MULTI-CITY SÉLECTIONNÉES
  // -----------------------
  Future<List<EventModel>> fetchSelected(
    List<String> cities, {
    bool resetParis = false,
  }) async {
    final lower = cities.map((e) => e.toLowerCase()).toList();

    final List<Future<List<EventModel>>> tasks = [];

    if (lower.contains("paris"))
      tasks.add(_paris.fetchEvents(reset: resetParis));
    if (lower.contains("lille")) tasks.add(_lille.fetchEvents());
    if (lower.contains("nantes")) tasks.add(_nantes.fetchEvents());
    if (lower.contains("lyon")) tasks.add(_lyon.fetchEvents());
    if (lower.contains("bordeaux")) tasks.add(_bordeaux.fetchEvents());
    if (lower.contains("toulouse")) tasks.add(_toulouse.fetchEvents());
    if (lower.contains("marseille")) tasks.add(_marseille.fetchEvents());
    if (lower.contains("idf")) tasks.add(_idf.fetchEvents());

    if (tasks.isEmpty) return [];

    final results = await Future.wait(
      tasks.map((t) => t.catchError((_) => <EventModel>[])),
    );

    final merged = results.expand((e) => e).toList();

    final Map<String, EventModel> unique = {};
    for (final e in merged) unique[e.id] = e;

    final sorted = unique.values.toList()
      ..sort((a, b) {
        final da = a.dateStart ?? DateTime.now();
        final db = b.dateStart ?? DateTime.now();
        return da.compareTo(db);
      });

    return sorted;
  }
}
