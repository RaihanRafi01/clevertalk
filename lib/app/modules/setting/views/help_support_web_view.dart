import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview;

// Use an alias to avoid naming conflict with your local WebViewController
class HelpSupportWebViewScreen extends StatelessWidget {
  const HelpSupportWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebViewGetXController());

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            webview.WebViewWidget(controller: controller.webViewController),
            Obx(
                  () => controller.isLoading.value
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewGetXController extends GetxController {
  late final webview.WebViewController webViewController; // Use aliased import
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    webViewController = webview.WebViewController()
      ..setJavaScriptMode(webview.JavaScriptMode.unrestricted) // Updated method
      ..setNavigationDelegate(
        webview.NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              isLoading.value = false;
            }
          },
          onPageStarted: (String url) {
            isLoading.value = true;
          },
          onPageFinished: (String url) {
            isLoading.value = false;
          },
          onWebResourceError: (webview.WebResourceError error) {
            isLoading.value = false;
          },
          onNavigationRequest: (webview.NavigationRequest request) {
            return webview.NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://clevertalk.ai/pages/contact-us')); // Replace with your website URL
  }
}