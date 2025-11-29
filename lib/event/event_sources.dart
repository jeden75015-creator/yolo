List<Map<String, dynamic>> extractEvents(
  String city,
  Map<String, dynamic> jsonBody,
) {
  switch (city.toLowerCase()) {
    case 'paris':
      return (jsonBody['results'] as List)
          .map((e) => parseParisEvent(e))
          .toList();
    case 'lille':
      return (jsonBody['events'] as List)
          .map((e) => parseLilleEvent(e))
          .toList();
    // TODO: ajouter parseurs pour les autres villes
    default:
      return [];
  }
}

Map<String, dynamic> parseParisEvent(Map<String, dynamic> e) {
  return {
    'id': e['record']['id'],
    'source': 'paris',
    'source_event_id': e['record']['id'],
    'title': e['record']['fields']['title_fr'] ?? '',
    'description': e['record']['fields']['description'] ?? '',
    'start_date': e['record']['fields']['date_start'],
    'end_date': e['record']['fields']['date_end'],
    'timezone': 'Europe/Paris',
    'city': 'Paris',
    'region': 'Île-de-France',
    'department': '75',
    'country': 'FR',
    'address': e['record']['fields']['address_street'] ?? '',
    'lat': e['record']['geometry']['coordinates'][1],
    'lon': e['record']['geometry']['coordinates'][0],
    'category': e['record']['fields']['tags']?[0] ?? '',
    'tags': List<String>.from(e['record']['fields']['tags'] ?? []),
    'image_url': e['record']['fields']['cover_url'] ?? '',
    'external_url': e['record']['fields']['url'],
    'price_min': null,
    'price_max': null,
    'is_free': e['record']['fields']['price_type'] == 'gratuit',
    'age_min': null,
  };
}

Map<String, dynamic> parseLilleEvent(Map<String, dynamic> e) {
  return {
    'id': e['uid'],
    'source': 'lille',
    'source_event_id': e['uid'],
    'title': e['title']['fr'] ?? '',
    'description': e['description']['fr'] ?? '',
    'start_date': e['timings']?[0]['start'] ?? '',
    'end_date': e['timings']?[0]['end'] ?? '',
    'timezone': 'Europe/Paris',
    'city': e['location']['city'] ?? 'Lille',
    'region': 'Hauts-de-France',
    'department': '59',
    'country': 'FR',
    'address': e['location']['address'] ?? '',
    'lat': e['location']['lat'],
    'lon': e['location']['lon'],
    'category': e['keywords']?[0] ?? '',
    'tags': List<String>.from(e['keywords'] ?? []),
    'image_url': e['image']['original'] ?? '',
    'external_url': e['website'] ?? '',
    'price_min': null,
    'price_max': null,
    'is_free': e['price_detail']?['isFree'] ?? false,
    'age_min': null,
  };
}
