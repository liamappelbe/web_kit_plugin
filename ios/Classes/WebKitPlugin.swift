import Flutter
import UIKit
import WebKit

public class WebKitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = WebKitViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "web_kit_view")
  }
}

class WebKitViewFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return WebKitNativeView(
        frame: frame,
        viewIdentifier: viewId,
        arguments: args,
        binaryMessenger: messenger)
  }

  /// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class WebKitNativeView: NSObject, FlutterPlatformView {
  private var _view: UIView

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    _view = UIView()
    super.init()
    // iOS views can be created here
    createNativeView(view: _view)
  }

  func view() -> UIView {
    return _view
  }

  func createNativeView(view _view: UIView){
    let webConfiguration = WKWebViewConfiguration()
    let webView = WKWebView(frame: .zero, configuration: webConfiguration)
    webView.load(URLRequest(url: URL(string: "https://www.xkcd.com")!))
    webView.allowsBackForwardNavigationGestures = true
    webView.backgroundColor = UIColor.yellow
    webView.frame = CGRect(x: 0, y: 0, width: 360, height: 480)
    _view.addSubview(webView)
  }
}
