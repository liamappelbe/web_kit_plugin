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

extension NSURLToUri on NSURL {
  Uri? get toUri {
    final str = absoluteString?.toString();
    if (str == null) return null;
    return Uri.tryParse(str);
  }
}

extension NavigationDecisionToWKNavigationActionPolicy on NavigationDecision {
  int get toWKNavigationActionPolicy {
    switch (this) {
      case NavigationDecision.prevent:
        return WKNavigationActionPolicy.WKNavigationActionPolicyCancel;
      case NavigationDecision.navigate:
        return WKNavigationActionPolicy.WKNavigationActionPolicyAllow;
    }
  }
}

extension NSErrorToWebResourceError on NSError {
  WebResourceError toWebResourceError(NSURL? url) => WebResourceError(
        errorCode: code,
        description: localizedDescription?.toString() ?? '',
        errorType: _toWebResourceErrorType(code),
        isForMainFrame: true,
        url: url?.absoluteString?.toString(),
      );

  static WebResourceErrorType? _toWebResourceErrorType(int code) {
    switch (code) {
      case WKErrorCode.WKErrorUnknown:
        return WebResourceErrorType.unknown;
      case WKErrorCode.WKErrorWebContentProcessTerminated:
        return WebResourceErrorType.webContentProcessTerminated;
      case WKErrorCode.WKErrorWebViewInvalidated:
        return WebResourceErrorType.webViewInvalidated;
      case WKErrorCode.WKErrorJavaScriptExceptionOccurred:
        return WebResourceErrorType.javaScriptExceptionOccurred;
      case WKErrorCode.WKErrorJavaScriptResultTypeIsUnsupported:
        return WebResourceErrorType.javaScriptResultTypeIsUnsupported;
    }
    return null;
  }
}

class SwiftWebViewController extends PlatformWebViewController {
  SwiftWebViewController()
      : super.implementation(PlatformWebViewControllerCreationParams()) {
    final id = hashCode;
    _view = runOnPlatformThread(
            () => WebKitViewWrapper.alloc(_lib).initWithId_(id).pointer)
        .then((Pointer<ObjCObject> viewPtr) =>
            WebKitViewWrapper.castFromPointer(_lib, viewPtr));
    _setupObservers();
  }

  Future<void> _setupObservers() async {
    _onProgress = ObjCBlock_ffiVoid_ffiDouble.listener(_lib,
        (double progress) => _navigationDelegate?._onProgress?.call(progress));
    _onUrlChange = ObjCBlock_ffiVoid_StrongRefNSURL.listener(_lib,
        (StrongRef_NSURL? url) => _navigationDelegate?._onUrlChange?.call(url));
    (await _view)
      ..onProgress = _onProgress
      ..onUrlChange = _onUrlChange;
  }

  late Future<WebKitViewWrapper> _view;
  Future<Pointer<ObjCObject>> get _viewPtr async => (await _view).pointer;
  Future<void> get ready => _view;

  SwiftNavigationDelegate? _navigationDelegate;
  ObjCBlock_ffiVoid_ffiDouble? _onProgress;
  ObjCBlock_ffiVoid_StrongRefNSURL? _onUrlChange;

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
      final delegate =
          NavigationDelegateWrapper.castFromPointer(_lib, delegatePtr);
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
        super.implementation(PlatformNavigationDelegateCreationParams()) {
    setOnNavigationRequest(defaultDecidePolicyForNavigationAction);
  }

  NavigationDelegateWrapper _delegate;

  ObjCBlock_ffiVoid_NavigationActionWrapper_ClosureVoidInt?
      _decidePolicyForNavigationAction;
  static NavigationDecision defaultDecidePolicyForNavigationAction(
      NavigationRequest request) {
    return NavigationDecision.navigate;
  }

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {
    _decidePolicyForNavigationAction =
        ObjCBlock_ffiVoid_NavigationActionWrapper_ClosureVoidInt.listener(_lib,
            (NavigationActionWrapper action,
                Closure_Void_Int decisionHandler) async {
      final decision = await onNavigationRequest(NavigationRequest(
        url: action.request.URL?.absoluteString?.toString() ?? '',
        isMainFrame: action.targetFrame?.isMainFrame ?? true,
      ));
      decisionHandler.callWithArg_(decision.toWKNavigationActionPolicy);
    });
    _delegate.decidePolicyForNavigationAction =
        _decidePolicyForNavigationAction;
  }

  ObjCBlock_ffiVoid_StrongRefNSURL? _didStartProvisionalNavigation;
  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    _didStartProvisionalNavigation =
        ObjCBlock_ffiVoid_StrongRefNSURL.listener(_lib, (StrongRef_NSURL? url) {
      onPageStarted(url?.value.absoluteString?.toString() ?? '');
      url?.drop();
    });
    _delegate.didStartProvisionalNavigation = _didStartProvisionalNavigation;
  }

  ObjCBlock_ffiVoid_StrongRefNSURL? _didFinishNavigation;
  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    _didFinishNavigation =
        ObjCBlock_ffiVoid_StrongRefNSURL.listener(_lib, (StrongRef_NSURL? url) {
      onPageFinished(url?.value.absoluteString?.toString() ?? '');
      url?.drop();
    });
    _delegate.didFinishNavigation = _didFinishNavigation;
  }

  void Function(double)? _onProgress;
  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    _onProgress = (double fraction) => onProgress((100 * fraction).round());
  }

  ObjCBlock_ffiVoid_StrongRefNSError_StrongRefNSURL? _didFailNavigation;
  ObjCBlock_ffiVoid? _webContentProcessDidTerminate;
  @override
  Future<void> setOnWebResourceError(
      WebResourceErrorCallback onWebResourceError) async {
    _didFailNavigation =
        ObjCBlock_ffiVoid_StrongRefNSError_StrongRefNSURL.listener(_lib,
            (StrongRef_NSError error, StrongRef_NSURL? url) {
      onWebResourceError(error.value.toWebResourceError(url?.value));
      error.drop();
      url?.drop();
    });
    _delegate.didFailNavigation = _didFailNavigation;
    _delegate.didFailProvisionalNavigation = _didFailNavigation;

    _webContentProcessDidTerminate = ObjCBlock_ffiVoid.listener(_lib, () {
      onWebResourceError(WebResourceError(
        errorCode: WKErrorCode.WKErrorWebContentProcessTerminated,
        description: '',
        errorType: WebResourceErrorType.webContentProcessTerminated,
        isForMainFrame: true,
        url: null,
      ));
    });
    _delegate.webContentProcessDidTerminate = _webContentProcessDidTerminate;
  }

  void Function(StrongRef_NSURL?)? _onUrlChange;
  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {
    _onUrlChange = (StrongRef_NSURL? url) {
      onUrlChange(UrlChange(url: url?.value.absoluteString?.toString()));
      url?.drop();
    };
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
