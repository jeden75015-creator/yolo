// services/events/nantes_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class NantesEventService {
  final int limit = 100;

  Future<List<EventModel>> fetchEvents() async {
    final url =
        "https://data.nantesmetropole.fr/api/records/1.0/search/"
        "?dataset=244400404_agenda-evenements-nantes-nantes-metropole"
        "&rows=$limit&sort=-date&q=date>=#now()";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API Nantes error");

    final json = jsonDecode(res.body);

    final List records = json["records"] ?? [];

    return records.map((e) => EventModel.fromApi(e["fields"] ?? {})).toList();
  }
}
