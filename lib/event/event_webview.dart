import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EventWebView extends StatelessWidget {
  final String url;

  const EventWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Page officielle"),
        backgroundColor: Colors.orange,
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..loadRequest(Uri.parse(url))
          ..setJavaScriptMode(JavaScriptMode.unrestricted),
      ),
    );
  }
}
