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
    close() async {
      await widget.controller.loadHtmlString("<html></html>");
      Navigator.of(context).pop();
    }
    return Dialog.fullscreen(
      child: Stack(
        children: [
          WebViewWidget(controller: widget.controller),
          Positioned(
            top: 10,
            right: 8,
            child: IconButton(
              color: Colors.black.withOpacity(0.6),
              icon: Icon(Icons.close, size: 35,),
              onPressed: close,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              color: Colors.white,
              icon: Icon(Icons.close, size: 35,),
              onPressed: close,
            ),
          ),
        ],
      ),
    );
  }
}