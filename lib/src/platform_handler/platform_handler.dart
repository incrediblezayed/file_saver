import 'package:file_saver/src/messages.g.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/platform_handler/platform_handler_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.js_interop) 'package:file_saver/src/platform_handler/platform_handler_web.dart'
    //  ignore: uri_does_not_exist
    if (dart.library.io) 'package:file_saver/src/platform_handler/platform_handler_all.dart';

abstract class PlatformHandler {
  static PlatformHandler get instance {
    return getPlatformHandler();
  }

  Future<String?> saveFile(SaveRequest request);

  Future<String?> saveAs(SaveRequest request);

  Future<String?> saveToGallery(SaveRequest request);

  Future<String?> saveToDownloads(SaveRequest request);

  Future<String?> downloadLink(LinkDetails link, {String? name});
}
