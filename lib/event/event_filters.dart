// lib/event/events_by_filter_page.dart

import 'package:flutter/material.dart';
import 'event_model.dart';
import 'event_service.dart';
import 'event_card.dart';
import 'event_detail_page.dart';

class EventsByFilterPage extends StatefulWidget {
  final String title; // Ex: "Paris", "Bretagne"
  final String filterType; // "city" ou "region"
  final String filterValue; // ex: "paris", "bretagne"

  const EventsByFilterPage({
    super.key,
    required this.title,
    required this.filterType,
    required this.filterValue,
  });

  @override
  State<EventsByFilterPage> createState() => _EventsByFilterPageState();
}

class _EventsByFilterPageState extends State<EventsByFilterPage> {
  bool loading = true;
  List<EventModel> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  // CHARGEMENT: selon filterType -> appel service ville ou région
  Future<void> loadEvents() async {
    try {
      List<EventModel> result;
      if (widget.filterType == "city") {
        result = await EventService.getEventsByCity(widget.filterValue);
      } else {
        result = await EventService.getEventsByRegion(widget.filterValue);
      }

      setState(() {
        events = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(child: Text("Aucun événement trouvé."))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (_, i) {
                final e = events[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: e),
                      ),
                    );
                  },
                  child: EventCard(event: e,isFav: false, onToggleFavorite: () {  },
                   onOpenDetails: () {  },),
                );
              },
            ),
    );
  }
}
