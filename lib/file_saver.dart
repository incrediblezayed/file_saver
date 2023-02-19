import 'dart:async';
import 'dart:io';

import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/saver.dart';
import 'package:file_saver/src/utils/helpers.dart';
import 'package:file_saver/src/utils/mime_types.dart';
import 'package:flutter/foundation.dart';

export 'package:file_saver/src/utils/mime_types.dart';

class FileSaver {
  final String _somethingWentWrong =
      "Something went wrong, please report the issue https://www.github.com/incrediblezayed/file_saver/issues";
  late String directory = _somethingWentWrong;

  ///instance of file saver
  static FileSaver get instance => FileSaver();

  late Saver _saver;

  ///[saveFile] main method which saves the file for all platforms.
  ///name: Name of your file.
  ///
  /// bytes: Encoded File for saving.
  ///
  /// ext: Extension of file.
  ///
  /// mimeType (Mainly required for web): MimeType from enum MimeType..
  ///
  /// More Mimetypes will be added in future
  Future<String> saveFile(
      {required String name,
      Uint8List? bytes,
      File? file,
      String? filePath,
      String? link,
      String ext = "",
      MimeType mimeType = MimeType.other}) async {
    bytes = bytes ??
        await Helpers.getBytes(file: file, filePath: filePath, link: link);
    String mime = Helpers.getType(mimeType);
    String extension = Helpers.getExtension(extension: ext);
    try {
      _saver = Saver(
          fileModel: FileModel(
              name: name, bytes: bytes, ext: extension, mimeType: mime));
      if (kIsWeb) {
        directory = await _saver.saveFileForWeb();
      } else if (Platform.isAndroid) {
        directory = await _saver.saveFileForAndroid();
      } else {
        directory = await _saver.saveFileForOtherPlatforms();
      }
      return directory;
    } catch (e) {
      return directory;
    }
  }

  ///[saveAs] This method will open a Save As File dialog where user can select the location for saving file.
  ///name: Name of your file.
  ///
  /// bytes: Encoded File for saving.
  ///
  /// ext: Extension of file.
  ///
  /// mimeType: MimeType from enum MimeType..
  ///
  /// More Mimetypes will be added in future
  /// Note:- This Method only works on Android for time being and other platforms will be added soon
  Future<String?> saveAs(
      {required String name,
      Uint8List? bytes,
      File? file,
      String? filePath,
      String? link,
      required String ext,
      required MimeType mimeType}) async {
    bytes = bytes ??
        await Helpers.getBytes(file: file, filePath: filePath, link: link);
    String mimeTypeValue = Helpers.getType(mimeType);
    _saver = Saver(
        fileModel: FileModel(
            name: mimeType == MimeType.other
                ? "$name${Helpers.getExtension(extension: ext)}"
                : name,
            bytes: bytes,
            ext: ext,
            mimeType: mimeTypeValue));
    String? path = await _saver.saveAs();
    return path;
  }
}
