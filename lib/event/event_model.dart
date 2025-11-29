import 'package:latlong2/latlong.dart';

class ExternalEvent {
  final String id;
  final String source;
  final String sourceEventId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String timezone;
  final String city;
  final String region;
  final String department;
  final String country;
  final String address;
  final LatLng location;
  final String category;
  final List<String> tags;
  final String imageUrl;
  final String externalUrl;
  final double? priceMin;
  final double? priceMax;
  final bool isFree;
  final int? ageMin;
  final bool canCreateAppEvent;
  final double? distanceMeters;

  ExternalEvent({
    required this.id,
    required this.source,
    required this.sourceEventId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.timezone,
    required this.city,
    required this.region,
    required this.department,
    required this.country,
    required this.address,
    required this.location,
    required this.category,
    required this.tags,
    required this.imageUrl,
    required this.externalUrl,
    required this.priceMin,
    required this.priceMax,
    required this.isFree,
    this.ageMin,
    this.canCreateAppEvent = true,
    this.distanceMeters,
  });

  factory ExternalEvent.fromJson(Map<String, dynamic> json) {
    return ExternalEvent(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      sourceEventId: json['source_event_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      timezone: json['timezone'] ?? '',
      city: json['city'] ?? '',
      region: json['region'] ?? '',
      department: json['department'] ?? '',
      country: json['country'] ?? '',
      address: json['address'] ?? '',
      location: LatLng(json['lat'], json['lon']),
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['image_url'] ?? '',
      externalUrl: json['external_url'] ?? '',
      priceMin: (json['price_min'] as num?)?.toDouble(),
      priceMax: (json['price_max'] as num?)?.toDouble(),
      isFree: json['is_free'] ?? false,
      ageMin: json['age_min'],
      canCreateAppEvent: json['can_create_app_event'] ?? true,
      distanceMeters: (json['distance_m'] as num?)?.toDouble(),
    );
  }
}
