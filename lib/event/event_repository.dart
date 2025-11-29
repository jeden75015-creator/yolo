import 'event_service.dart';
import 'event_model.dart';

class EventRepository {
  final EventService _service = EventService();

  Future<List<ExternalEvent>> getEventsForCity(String city) async {
    return await _service.fetchEvents(city);
  }

  Future<List<ExternalEvent>> getNearbyEvents(double lat, double lon) async {
    return await _service.fetchNearbyEvents(lat: lat, lon: lon);
  }
}
