// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:web_kit_plugin/web_kit_plugin.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MaterialApp(home: WebViewExample()));

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    // #docregion webview_controller
    controller = WebViewController.fromPlatform(SwiftWebViewController())
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate.fromPlatform(
          SwiftNavigationDelegate(),
          onProgress: (int progress) {
            print("onProgress $progress");
          },
          onUrlChange: (UrlChange change) {
            print("onUrlChange ${change.url}");
          },
          onPageStarted: (String url) {
            print("onPageStarted $url");
          },
          onPageFinished: (String url) {
            print("onPageFinished $url");
          },
          onWebResourceError: (WebResourceError error) {
            print(
                "onWebResourceError ${error.errorCode}\t${error.description}\t"
                "${error.errorType}\t${error.isForMainFrame}\t${error.url}");
          },
          onNavigationRequest: (NavigationRequest request) {
            print("onNavigationRequest ${request.url}");
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://flutter.dev'));
    // #enddocregion webview_controller
  }

  // #docregion webview_widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Simple Example')),
      body: WebViewWidget.fromPlatform(platform: SwiftWebViewWidget(
        PlatformWebViewWidgetCreationParams(
          controller: controller.platform,
        ),
      )),
    );
  }
  // #enddocregion webview_widget
}
