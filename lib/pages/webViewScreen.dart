import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfWebViewScreen extends StatefulWidget {
  final String pdfUrl;

  const PdfWebViewScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PdfWebViewScreenState createState() => _PdfWebViewScreenState();
}

class _PdfWebViewScreenState extends State<PdfWebViewScreen> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('Loading progress: $progress%');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onHttpError: (HttpResponseError error) {
            // print('HTTP error: ${error.statusCode}');
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      );

    // Ensure the URL is properly encoded
    final encodedUrl = Uri.encodeFull(widget.pdfUrl);
    print('PDF URL: $encodedUrl'); // Debug log for the URL
    _controller.loadRequest(Uri.parse(
        'https://docs.google.com/gview?embedded=true&url=$encodedUrl'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF Viewer"),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
