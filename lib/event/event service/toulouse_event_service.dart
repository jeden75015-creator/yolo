// services/events/toulouse_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class ToulouseEventService {
  final int limit = 50;

  Future<List<EventModel>> fetchEvents() async {
    final url =
        "https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/"
        "agenda-des-manifestations-culturelles-so-toulouse/records?limit=$limit";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API Toulouse error");

    final json = jsonDecode(res.body);

    final List results = json["results"] ?? [];

    return results.map((e) => EventModel.fromApi(e)).toList();
  }
}
