import Cocoa
import FlutterMacOS

public class FileSaverPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "file_saver", binaryMessenger: registrar.messenger)
    let instance = FileSaverPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "saveAs":
        guard let arguments = call.arguments as? [String: Any?] else {
            result(FlutterError(code: "Invalid Arguments", message: "Invalid Arguments were supplied", details: nil))
            return
        }
        let params = Params(arguments)
        DispatchQueue.main.async {
            let dialog = Dialog()
            dialog.openSaveAsDialog(params: params, result: result)
        }
            default:
      result(FlutterMethodNotImplemented)
    }
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
