// 📁 event/event_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yolo/lib/event/event_repository.dart';
import 'package:yolo/lib/event/event_model.dart';

class EventMap extends StatefulWidget {
  const EventMap({super.key});

  @override
  State<EventMap> createState() => _EventMapState();
}

class _EventMapState extends State<EventMap> {
  List<ExternalEvent> _events = [];
  LatLng? _userLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      final events = await EventRepository().getNearbyEvents(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _userLocation = latLng;
        _events = events;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _userLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      options: MapOptions(center: _userLocation, zoom: 13.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.yolo',
        ),
        MarkerLayer(
          markers: _events
              .map(
                (e) => Marker(
                  width: 80,
                  height: 80,
                  point: e.location,
                  builder: (_) => GestureDetector(
                    onTap: () {
                      // TODO : ouvrir modal d’event avec infos + actions
                    },
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.deepOrange,
                      size: 36,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        Marker(
          width: 60,
          height: 60,
          point: _userLocation!,
          builder: (_) =>
              const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
        ),
      ],
    );
  }
}
