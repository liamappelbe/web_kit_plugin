import 'dart:ffi';
import 'dart:io';

import 'web_kit_plugin_bindings_generated.dart';

String hello() => WebKitWrapper.new1(_lib).sayHello().toString();

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
