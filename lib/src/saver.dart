import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';

class Saver {
  final FileModel fileModel;
  Saver({required this.fileModel});
  final PlatformHandler _platformHandler = PlatformHandler.instance;
  Future<String?> save() async {
    return await _platformHandler.saveFile(fileModel);
  }

  Future<String?> saveAs() async {
    return await _platformHandler.saveAs(fileModel);
  }
}
