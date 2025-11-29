import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event_model.dart';
import 'event_sources.dart';

class EventService {
  final Map<String, String> cityEndpoints = {
    'paris':
        'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/que-faire-a-paris-/records?limit=50',
    'lille':
        'https://api.openagenda.com/v2/agendas/48962291/events?relative[0]=current&relative[1]=upcoming&detailed=1&key=725aa624f0d840818ad071a2023f209d',
    'nantes':
        'https://data.nantesmetropole.fr/api/records/1.0/search/?dataset=244400404_agenda-evenements-nantes-nantes-metropole&q=date>=#now()&rows=200',
    'lyon':
        'https://public.opendatasoft.com/api/records/1.0/search/?dataset=evenements-publics-openagenda&q=lyon+AND+lastdate_end>=#NOW()&rows=100',
    'bordeaux':
        'https://opendata.bordeaux-metropole.fr/api/records/1.0/search/?dataset=met_agenda&q=lastdate_end>=#now()&rows=100',
    'toulouse':
        'https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records?limit=20',
    'idf':
        'https://data.iledefrance.fr/api/explore/v2.1/catalog/datasets/evenements-publics-cibul/records?where=lastdate_end > now()&limit=100',
  };

  Future<List<ExternalEvent>> fetchEvents(String city) async {
    final url = cityEndpoints[city.toLowerCase()];
    if (url == null) return [];
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];

    final jsonBody = json.decode(response.body);
    final List events = extractEvents(city, jsonBody);

    return events.map((e) => ExternalEvent.fromJson(e)).toList();
  }

  Future<List<ExternalEvent>> fetchNearbyEvents({
    required double lat,
    required double lon,
    int radius = 3000,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      'https://tonapi.com/suggestions/now?lat=$lat&lon=$lon&radius=$radius&limit=$limit',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => ExternalEvent.fromJson(e)).toList();
  }
}
