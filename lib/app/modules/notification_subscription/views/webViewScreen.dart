import 'package:flutter/material.dart';
import '../../../data/services/api_services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final VoidCallback onUrlMatched;

  const WebViewScreen({super.key, required this.url, required this.onUrlMatched});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            // Handle page start if needed
          },
          onUrlChange: (UrlChange change) {
            print('::::::::::::::::::::::::::::::URL::::${change.url}');
            if (change.url == '${ApiService().baseUrl}pay/success/') {
              // Navigate back to the previous screen
              Navigator.pop(context);
              widget.onUrlMatched();
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource errors
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}