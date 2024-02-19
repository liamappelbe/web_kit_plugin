import 'package:flutter/material.dart';
import 'dart:async';

import 'package:web_kit_plugin/web_kit_plugin.dart' as web_kit_plugin;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String hello;

  @override
  void initState() {
    super.initState();
    hello = web_kit_plugin.hello();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(hello),
        ),
        body: web_kit_plugin.WebView(),
      ),
    );
  }
}
