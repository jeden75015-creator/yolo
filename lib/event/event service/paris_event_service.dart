// services/paris_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../event_model.dart';
import '../event_sources.dart';

class ParisEventService {
  final int limit = 100; // Augmenté pour réduire le nombre de requêtes
  
  /// Récupère TOUS les événements de Paris depuis l'API
  /// Filtre pour garder uniquement les dates > aujourd'hui
  /// Filtre les champs null
  /// Trie les résultats par date de début
  Future<List<ExternalEvent>> fetchAllEvents() async {
    final List<ExternalEvent> allEvents = [];
    int offset = 0;
    bool hasMore = true;
    final now = DateTime.now();

    // Boucle de pagination pour récupérer TOUTES les données
    while (hasMore) {
      final uri = Uri.parse(
        'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/que-faire-a-paris-/records'
        '?limit=$limit&offset=$offset',
      );

      try {
        final res = await http.get(uri);
        if (res.statusCode != 200) {
          throw Exception("Erreur API Paris : ${res.statusCode}");
        }

        final json = jsonDecode(res.body);
        final List results = json["results"] ?? [];
        
        // Si aucun résultat, on arrête la pagination
        if (results.isEmpty) {
          hasMore = false;
          break;
        }

        // Parse les événements
        for (var raw in results) {
          try {
            final parsed = parseParisEvent(raw);
            
            // Filtrage des champs null et vérification des dates
            if (_isValidEvent(parsed, now)) {
              final event = ExternalEvent.fromJson(parsed);
              allEvents.add(event);
            }
          } catch (e) {
            // Ignore les événements mal formés
            continue;
          }
        }

        offset += limit;
        
        // Si moins de résultats que la limite, c'est la dernière page
        if (results.length < limit) {
          hasMore = false;
        }
      } catch (e) {
        // En cas d'erreur, on arrête et retourne ce qu'on a déjà
        hasMore = false;
      }
    }

    // Tri par date de début (ordre croissant)
    allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    return allEvents;
  }

  /// Vérifie qu'un événement est valide :
  /// - Date de fin > aujourd'hui
  /// - Champs essentiels non null/vides
  bool _isValidEvent(Map<String, dynamic> event, DateTime now) {
    try {
      // Vérifier que la date de fin existe et est dans le futur
      final endDateStr = event['end_date'];
      if (endDateStr == null || endDateStr.toString().isEmpty) {
        return false;
      }
      
      final endDate = DateTime.parse(endDateStr);
      if (endDate.isBefore(now)) {
        return false;
      }

      // Vérifier les champs essentiels
      if (event['title'] == null || event['title'].toString().trim().isEmpty) {
        return false;
      }

      if (event['start_date'] == null || event['start_date'].toString().isEmpty) {
        return false;
      }

      // Vérifier la géolocalisation
      if (event['lat'] == null || event['lon'] == null) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Méthode de compatibilité (retourne ExternalEvent au lieu de EventModel)
  Future<List<ExternalEvent>> fetchEvents({bool reset = false}) async {
    // Cette méthode appelle maintenant fetchAllEvents pour avoir toutes les données
    return await fetchAllEvents();
  }
}
