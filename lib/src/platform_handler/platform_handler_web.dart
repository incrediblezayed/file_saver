import 'dart:developer';

import 'package:file_saver/file_saver_web.dart';
import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';

PlatformHandler getPlatformHandler() {
  return PlatformHandlerWeb();
}

class PlatformHandlerWeb extends PlatformHandler {
  @override
  Future<String?> saveFile(FileModel fileModel) async {
    bool result = await FileSaverWeb.downloadFile(fileModel);
    if (result) {
      return 'Downloads';
    }
    return null;
  }

  @override
  Future<String?> saveAs(FileModel fileModel) async {
    await FileSaverWeb.saveAs(fileModel);
    log('File saved as ${fileModel.name}${fileModel.ext}');
    return null;
  }
}
