// services/events/lyon_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class LyonEventService {
  final int limit = 100;

  Future<List<EventModel>> fetchEvents() async {
    final url =
        "https://public.opendatasoft.com/api/records/1.0/search/"
        "?dataset=evenements-publics-openagenda"
        "&rows=$limit&q=lyon AND lastdate_end>=#NOW()";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API Lyon error");

    final json = jsonDecode(res.body);

    final List records = json["records"] ?? [];

    return records.map((e) => EventModel.fromApi(e["fields"])).toList();
  }
}
