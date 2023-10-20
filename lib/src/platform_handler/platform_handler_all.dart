import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';
import 'package:file_saver/src/utils/helpers.dart';
import 'package:flutter/services.dart';

PlatformHandler getPlatformHandler() {
  return PlatformHandlerAll();
}

class PlatformHandlerAll extends PlatformHandler {
  final MethodChannel _channel = const MethodChannel('file_saver');
  final String _saveAs = 'saveAs';
  final String _saveFile = 'saveFile';

  final String _somethingWentWrong =
      'Something went wrong, please report the issue https://www.github.com/incrediblezayed/file_saver/issues';
  late String directory = _somethingWentWrong;

  final String _issueLink =
      'https://www.github.com/incrediblezayed/file_saver/issues';

  Future<String> saveFileForAndroid(FileModel fileModel) async {
    try {
      directory =
          await _channel.invokeMethod<String>(_saveFile, fileModel.toMap()) ??
              '';
    } catch (e) {
      log('Error: $e');
    }
    return directory;
  }

  Future<String> saveFileForOtherPlatforms(FileModel fileModel) async {
    String path = '';
    path = await Helpers.getDirectory() ?? '';
    if (path == '') {
      log('The path was found null or empty, please report the issue at $_issueLink');
    } else {
      String filePath = '$path/${fileModel.name}${fileModel.ext}';
      final File file = File(filePath);
      await file.writeAsBytes(fileModel.bytes);
      bool exist = await file.exists();
      if (exist) {
        directory = file.path;
      } else {
        log('File was not created');
      }
    }
    return directory;
  }

  @override
  Future<String?> saveFile(FileModel fileModel) async {
    if (Platform.isAndroid) {
      return await saveFileForAndroid(fileModel);
    } else {
      return await saveFileForOtherPlatforms(fileModel);
    }
  }

  ///Open File Manager
  @override
  Future<String?> saveAs(FileModel fileModel) async {
    String? path;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      path = await _channel.invokeMethod<String>(_saveAs, fileModel.toMap());
    } else if (Platform.isWindows) {
      final Int64List? bytes = await _channel.invokeMethod<Int64List?>('saveAs', fileModel.toMap());
      path = bytes == null ? null : String.fromCharCodes(bytes);
    } else {
      throw UnimplementedError('Unimplemented Error');
    }
    return path;
  }
}
