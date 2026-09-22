import 'package:file_saver/file_saver_web.dart';
import 'package:file_saver/src/messages.g.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';

PlatformHandler getPlatformHandler() {
  return PlatformHandlerWeb();
}

class PlatformHandlerWeb extends PlatformHandler {
  @override
  Future<String?> saveFile(SaveRequest request) async {
    bool result = await FileSaverWeb.downloadFile(request);
    if (result) {
      return 'Downloads';
    }
    return null;
  }

  @override
  Future<String?> saveAs(SaveRequest request) async {
    return saveFile(request);
  }

  @override
  Future<String?> saveToGallery(SaveRequest request) {
    throw UnsupportedError(
      'saveToGallery is only supported on Android and iOS.',
    );
  }

  @override
  Future<String?> downloadLink(LinkDetails link, {String? name}) async {
    final result = FileSaverWeb.downloadLink(link.link, name: name);
    if (result) {
      return 'Downloads';
    }
    return null;
  }
}
