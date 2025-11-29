// services/events/bordeaux_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class BordeauxEventService {
  final int limit = 100;

  Future<List<EventModel>> fetchEvents() async {
    final url =
        "https://opendata.bordeaux-metropole.fr/api/records/1.0/search/"
        "?dataset=met_agenda"
        "&rows=$limit&q=lastdate_end>=#now()";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API Bordeaux error");

    final json = jsonDecode(res.body);

    final List records = json["records"] ?? [];

    return records.map((e) => EventModel.fromApi(e["fields"])).toList();
  }
}
