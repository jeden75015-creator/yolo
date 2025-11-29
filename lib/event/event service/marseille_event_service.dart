// services/events/marseille_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class MarseilleEventService {
  final int limit = 50;

  Future<List<EventModel>> fetchEvents() async {
    final url =
        "https://data.ampmetropole.fr/api/explore/v2.1/catalog/datasets/"
        "point-dinteret-datatourisme-multi-niveaux/records?limit=$limit";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API Marseille error");

    final json = jsonDecode(res.body);

    final List results = json["results"] ?? [];

    return results.map((e) => EventModel.fromApi(e)).toList();
  }
}
