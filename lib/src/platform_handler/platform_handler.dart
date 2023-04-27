import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/platform_handler/platform_handler_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'package:file_saver/src/platform_handler/platform_handler_web.dart'
    //  ignore: uri_does_not_exist
    if (dart.library.io) 'package:file_saver/src/platform_handler/platform_handler_all.dart';

abstract class PlatformHandler {
  static PlatformHandler get instance {
    return getPlatformHandler();
  }

  Future<String?> saveFile(FileModel fileModel);

  Future<String?> saveAs(FileModel fileModel);
}
