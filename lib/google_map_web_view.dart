import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class GoogleMapWebView extends StatelessWidget {
  final String apiKey;
  final double latitude;
  final double longitude;
  final double zoom;

  const GoogleMapWebView({
    super.key,
    required this.apiKey,
    this.latitude = 48.8566,
    this.longitude = 2.3522,
    this.zoom = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Création de l'iframe
    final iframe = web.HTMLIFrameElement()
      ..src =
          "https://www.google.com/maps/embed/v1/view?key=$apiKey&center=$latitude,$longitude&zoom=$zoom"
      ..style.border = "0"
      ..style.width = "100%"
      ..style.height = "100%";

    // Ajout à la DOM
    final viewId = "map-iframe-${DateTime.now().millisecondsSinceEpoch}";
    web.document.getElementById(viewId)?.remove();
    web.document.body!.append(iframe);

    return HtmlElementView(viewType: viewId);
  }
}
