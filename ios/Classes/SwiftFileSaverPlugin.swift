import Flutter
import UIKit

public class SwiftFileSaverPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "file_saver", binaryMessenger: registrar.messenger())
    let instance = SwiftFileSaverPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    var dialog = Dialog()
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method=="saveAs" else {
        result(FlutterMethodNotImplemented)
        return
    }
    if call.method=="saveAs" {
        guard let arguments = call.arguments as? [String: Any?] else {
            result(FlutterError(code: "Invalid Arguments", message: "Invalid Arguments were supplied", details: nil))
            return
        }
        let params = Params(arguments)
        if params.bytes==nil||params.ext==nil||params.fileName==nil {
            print("Invalid Arguments")
            result(FlutterError(code: "Invalid_Arguments", message: "Some Of the arguments are null", details: nil))
        }else{
            dialog.openFileManager(byteData: params.bytes!, fileName: params.fileName!,ext: params.ext!, result: result)
        }
    } else {
        result("iOS no supported method found")
    }
    // result("iOS " + UIDevice.current.systemVersion)
  }
}

struct Params {
    let fileName: String?
    let bytes: [UInt8]?
    let ext: String?
    init(_ d: [String: Any?]) {
        fileName = d["name"] as? String
        let uint8List = d["bytes"] as? FlutterStandardTypedData
        if(uint8List==nil){
            bytes = nil
        }else{
            bytes = [UInt8](uint8List!.data)
        }
        ext = d["ext"] as? String
    }
}
