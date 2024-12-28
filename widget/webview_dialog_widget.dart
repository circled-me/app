import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewDialog extends StatefulWidget {
  final WebViewController controller;

  WebViewDialog({required this.controller});

  @override
  _WebViewDialogState createState() => _WebViewDialogState();
}

class _WebViewDialogState extends State<WebViewDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Stack(
        children: [
          WebViewWidget(controller: widget.controller),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              color: Colors.white,
              icon: Icon(Icons.close),
              onPressed: () async {
                await widget.controller.loadHtmlString("<html></html>");
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}