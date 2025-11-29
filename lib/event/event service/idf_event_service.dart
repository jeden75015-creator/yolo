// services/events/idf_event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yolo/event/event_model.dart';

class IDFEventService {
  final int limit = 100;

  Future<List<EventModel>> fetchEvents() async {
    final url =
        "https://opendata.visitparisregion.com/api/explore/v2.1/catalog/datasets/"
        "evenements-publics-cibul/records?limit=$limit&where=lastdate_end > now()";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception("API IDF error");

    final json = jsonDecode(res.body);

    final List results = json["results"] ?? [];

    return results.map((e) => EventModel.fromApi(e)).toList();
  }
}
