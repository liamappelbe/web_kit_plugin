import 'dart:ffi';
import 'dart:math';
import 'dart:io';

import 'web_kit_plugin_bindings_generated.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class WebView extends StatelessWidget {
  WebView({super.key});

  late ObjCBlock_ffiVoid_WebKitViewWrapper onCreate;

  Widget build(BuildContext context) {
    const String viewType = 'web_kit_view';

    onCreate = ObjCBlock_ffiVoid_WebKitViewWrapper.listener(_lib,
        (WebKitViewWrapper webKitView) {
      webKitView.loadWithUrl_(NSString(_lib, 'https://www.xkcd.com'));
    });
    WebKitViewWrapper.setOnCreateWithId_closure_(_lib, hashCode, onCreate);

    final view = UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: hashCode,
      creationParamsCodec: const StandardMessageCodec(),
    );

    return view;
  }
}

const String _libName = 'web_kit_plugin';

/// The dynamic library in which the symbols for [WebKitPluginBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final WebKitPluginBindings _lib = WebKitPluginBindings(_dylib);
