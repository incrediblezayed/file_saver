import Flutter
import UIKit

public class SwiftFileSaverPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "file_saver", binaryMessenger: registrar.messenger())
    let instance = SwiftFileSaverPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method=='saveAs' else {
        result(FlutterMethodNotImplemented)
    }
    result("iOS " + UIDevice.current.systemVersion)
  }
}
