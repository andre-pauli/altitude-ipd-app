import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TelegramWebView extends StatelessWidget {
  // WebViewController controller = WebViewController()
  //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
  //   ..setNavigationDelegate(
  //     NavigationDelegate(
  //       onProgress: (int progress) {
  //         // Update loading bar.
  //       },
  //       onPageStarted: (String url) {},
  //       onPageFinished: (String url) {},
  //       onHttpError: (HttpResponseError error) {},
  //       onWebResourceError: (WebResourceError error) {},
  //       onNavigationRequest: (NavigationRequest request) {
  //         if (request.url
  //             .startsWith('https://t.me/@andrepaulii?start=SuaMensagem')) {
  //           return NavigationDecision.prevent;
  //         }
  //         return NavigationDecision.navigate;
  //       },
  //     ),
  //   )
  //   ..loadRequest(Uri.parse('https://t.me/@andrepaulii?start=SuaMensagem'));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversa no Telegram"),
      ),
      body: Text(''),
    );
  }
}
