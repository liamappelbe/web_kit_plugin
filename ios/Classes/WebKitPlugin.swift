import Flutter
import Foundation
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

@objc class WebKitViewWrapper : NSObject {
  // TODO: If we could pass a callback through UiKitView's creationParams, this
  // wouldn't be necessary. That might be possible if we can write a custom
  // MessageCodec.
  typealias OnCreate = (WebKitViewWrapper) -> Void
  private static var _onCreate: [Int: OnCreate] = [:]

  private var _webView: WKWebView

  init(id: Int) {
    let webConfiguration = WKWebViewConfiguration()
    _webView = WKWebView(frame: .zero, configuration: webConfiguration)

    super.init()

    _webView.allowsBackForwardNavigationGestures = true
    _webView.backgroundColor = UIColor.yellow

    let onCreate = WebKitViewWrapper._onCreate.removeValue(forKey: id)
    onCreate?(self)
  }

  @objc static func setOnCreate(id: Int, closure: @escaping OnCreate) {
    WebKitViewWrapper._onCreate[id] = closure
  }

  @objc func load(url: String) {
    _webView.load(URLRequest(url: URL(string: url)!))
  }

  func view() -> UIView {
    return _webView
  }
}

class WebKitNativeView: NSObject, FlutterPlatformView {
  private var _webView: WebKitViewWrapper

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    _webView = WebKitViewWrapper(id: args as! Int)
    super.init()
  }

  func view() -> UIView {
    return _webView.view()
  }
}
