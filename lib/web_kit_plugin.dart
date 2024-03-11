import 'dart:ffi';
import 'dart:math';
import 'dart:io';
import 'dart:ui';

import 'web_kit_plugin_bindings_generated.dart';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

extension UriToNSURL on Uri {
  NSURL get toNSURL => NSURL.URLWithString_(_lib, toString().toNSString(_lib))!;
}

extension Uint8ListToNSData on Uint8List {
  NSData get toNSData {
    final buffer = calloc<Uint8>(length);
    try {
      buffer.asTypedList(length).setAll(0, this);
      return NSData.dataWithBytes_length_(_lib, buffer.cast(), length);
    } finally {
      calloc.free(buffer);
    }
  }
}

class SwiftWebViewController extends PlatformWebViewController {
  SwiftWebViewController() :
      super.implementation(PlatformWebViewControllerCreationParams()) {
    final id = hashCode;
    _view = runOnPlatformThread(() =>
        WebKitViewWrapper.alloc(_lib).initWithId_(id).pointer
    ).then((Pointer<ObjCObject> viewPtr) =>
        WebKitViewWrapper.castFromPointer(_lib, viewPtr));
  }

  late Future<WebKitViewWrapper> _view;
  Future<Pointer<ObjCObject>> get _viewPtr async => (await _view).pointer;
  Future<void> get ready => _view;

  SwiftNavigationDelegate? _navigationDelegate;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    final viewPtr = await _viewPtr;
    await runOnPlatformThread(() async {
      final view = WebKitViewWrapper.castFromPointer(_lib, viewPtr);
      switch (javaScriptMode) {
        case JavaScriptMode.disabled:
          return view.setJavaScriptEnabledWithEnabled_(false);
        case JavaScriptMode.unrestricted:
          return view.setJavaScriptEnabledWithEnabled_(true);
      }
    });
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    final viewPtr = await _viewPtr;
    await runOnPlatformThread(() async {
      final view = WebKitViewWrapper.castFromPointer(_lib, viewPtr);
      view.setBackgroundColorWithRed_green_blue_alpha_(
        color.red / 0xFF,
        color.green / 0xFF,
        color.blue / 0xFF,
        color.alpha / 0xFF,
      );
    });
  }

  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {
    final viewPtr = await _viewPtr;
    _navigationDelegate = handler as SwiftNavigationDelegate;
    final delegatePtr = _navigationDelegate!._delegate.pointer;
    await runOnPlatformThread(() async {
      final view = WebKitViewWrapper.castFromPointer(_lib, viewPtr);
      final delegate = NavigationDelegateWrapper.castFromPointer(_lib, delegatePtr);
      view.setNavigationDelegateWithDelegate_(delegate);
    });
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    final viewPtr = await _viewPtr;
    await runOnPlatformThread(() async {
      final view = WebKitViewWrapper.castFromPointer(_lib, viewPtr);
      final req = NSMutableURLRequest.requestWithURL_(_lib, params.uri.toNSURL);
      req.HTTPMethod = params.method.name.toNSString(_lib);
      req.HTTPBody = params.body?.toNSData;
      for (final entry in params.headers.entries) {
        req.addValue_forHTTPHeaderField_(
            entry.key.toNSString(_lib), entry.value.toNSString(_lib));
      }
      view.loadWithRequest_(req);
    });
  }
}

class SwiftWebViewWidget extends PlatformWebViewWidget {
  SwiftWebViewWidget(PlatformWebViewWidgetCreationParams params)
      : super.implementation(params);

  @override
  Widget build(BuildContext context) {
    final controller = params.controller as SwiftWebViewController;
    return FutureBuilder(
        future: controller.ready,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.hasData) {
            return UiKitView(
              key: ValueKey<PlatformWebViewWidgetCreationParams>(params),
              viewType: 'plugins.flutter.io/swift_webview',
              onPlatformViewCreated: (_) {},
              layoutDirection: params.layoutDirection,
              gestureRecognizers: params.gestureRecognizers,
              creationParams: params.controller.hashCode,
              creationParamsCodec: const StandardMessageCodec(),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Text('Waiting...');
          }
        },
    );
  }
}

class SwiftNavigationDelegate extends PlatformNavigationDelegate {
  SwiftNavigationDelegate()
      : _delegate = NavigationDelegateWrapper.new1(_lib),
      _decidePolicyForNavigationAction = ObjCBlock_ffiVoid_WKNavigationAction_ClosureVoidInt.listener(
          _lib, defaultDecidePolicyForNavigationAction),
      super.implementation(PlatformNavigationDelegateCreationParams()) {
    _delegate.decidePolicyForNavigationAction =
        _decidePolicyForNavigationAction;
  }

  NavigationDelegateWrapper _delegate;

  ObjCBlock_ffiVoid_WKNavigationAction_ClosureVoidInt _decidePolicyForNavigationAction;
  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {
    // _decidePolicyForNavigationAction = ObjCBlock_ffiVoid_WKNavigationAction_ClosureVoidInt.listener(
    //       _lib, (WKNavigationAction action, ObjCBlock_ffiVoid_ffiLong decisionHandler) {
    //         final decision = onNavigationRequest(NavigationRequest(
    //           url: action.request.url,
    //           isMainFrame: action.targetFrame.isMainFrame,
    //         ));
    //         decisionHandler(decision.WKNavigationActionPolicy);
    //       }
    //     );
    // _delegate.decidePolicyForNavigationAction =
    //     _decidePolicyForNavigationAction;
  }
  static void defaultDecidePolicyForNavigationAction(
      WKNavigationAction action, Closure_Void_Int decisionHandler) {
    decisionHandler.callWithArg_(1);
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
  }

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
  }

  @override
  Future<void> setOnWebResourceError(
      WebResourceErrorCallback onWebResourceError) async {
  }

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {
  }

  @override
  Future<void> setOnHttpAuthRequest(
      HttpAuthRequestCallback onHttpAuthRequest) async {
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
