// services/events/lille_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class LilleEventService {
  int page = 0;
  final int limit = 50;

  Future<List<EventModel>> fetchEvents({bool reset = false}) async {
    if (reset) page = 0;

    final url =
        "https://api.openagenda.com/v2/agendas/48962291/events"
        "?limit=$limit&offset=${page * limit}"
        "&relative[]=current&relative[]=upcoming"
        "&key=725aa624f0d840818ad071a2023f209d";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API Lille error");

    final json = jsonDecode(res.body);

    final List list = json["events"] ?? [];

    page++;

    return list.map((raw) => EventModel.fromApi(raw)).toList();
  }
}
