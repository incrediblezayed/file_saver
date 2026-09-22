import 'package:file_saver/src/messages.g.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';

class Saver {
  final SaveRequest request;
  Saver({required this.request});
  final PlatformHandler _platformHandler = PlatformHandler.instance;
  Future<String?> save() async {
    return await _platformHandler.saveFile(request);
  }

  Future<String?> saveAs() async {
    return await _platformHandler.saveAs(request);
  }
}
