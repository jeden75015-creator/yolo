// services/paris_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../event_model.dart';

class ParisEventService {
  final int limit = 50;
  int offset = 0;

  Future<List<EventModel>> fetchEvents({bool reset = false}) async {
    if (reset) offset = 0;

    final uri = Uri.parse(
      'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/que-faire-a-paris-/records'
      '?limit=$limit&offset=$offset',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception("Erreur API Paris : ${res.statusCode}");
    }

    final json = jsonDecode(res.body);

    // La structure Paris (v2.1) :
    // {
    //   "results": [
    //      {
    //        "id": "...",
    //        "title": "...",
    //        "description": "...",
    //        ...
    //      }
    //   ]
    // }

    final List list = json["results"] ?? [];

    offset += limit;

    return list
        .map((raw) => EventModel.fromApi(raw as Map<String, dynamic>))
        .toList();
  }
}
