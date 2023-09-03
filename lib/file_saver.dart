import 'dart:async';
import 'dart:io';

import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/saver.dart';
import 'package:file_saver/src/utils/helpers.dart';
import 'package:file_saver/src/utils/mime_types.dart';
import 'package:flutter/foundation.dart';

export 'package:file_saver/src/models/link_details.dart';
export 'package:file_saver/src/utils/mime_types.dart';

class FileSaver {
  final String _somethingWentWrong =
      'Something went wrong, please report the issue https://www.github.com/incrediblezayed/file_saver/issues';
  late String directory = _somethingWentWrong;

  ///instance of file saver
  static FileSaver get instance => FileSaver();

  late Saver _saver;

  ///[saveFile] main method which saves the file for all platforms.
  ///
  /// [name]: Name of your file.
  ///
  /// [bytes]: Encoded File for saving
  /// Or
  /// [file]: File to be saved.
  /// Or
  /// [filePath]: Path of file to be saved.
  /// Or
  /// [link]: Link & header of file to be saved.
  /// [LinkDetails] is a model which contains [link] & [headers]
  /// LinkDetails(
  ///   link: 'https://www.google.com',
  ///  headers: {
  ///    'your-header': 'header-value',
  ///    },
  /// ),
  ///
  /// Out of these 4 parameters, only one is required.
  ///
  /// [ext]: Extension of file.
  ///
  /// mimeType (Mainly required for web): MimeType from enum MimeType..
  ///
  /// More Mimetypes will be added in future
  Future<String> saveFile(
      {required String name,
      Uint8List? bytes,
      File? file,
      String? filePath,
      LinkDetails? link,
      String ext = '',
      MimeType mimeType = MimeType.other,
      String? customMimeType}) async {
    assert(mimeType != MimeType.custom || customMimeType != null,
        'customMimeType is required when mimeType is MimeType.custom');

    String extension = Helpers.getExtension(extension: ext);
    final isFile = file != null || filePath != null;
    if (!isFile) {
      bytes = bytes ??
          await Helpers.getBytes(file: file, filePath: filePath, link: link);
    }
    try {
      if (isFile) {
        directory = await saveFileOnly(
              name: name,
              file: file ?? File(filePath!),
              ext: extension,
              mimeType: mimeType,
            ) ??
            _somethingWentWrong;
      } else {
        _saver = Saver(
            fileModel: FileModel(
                name: name,
                bytes: bytes!,
                ext: extension,
                mimeType:
                    mimeType.type.isEmpty ? customMimeType! : mimeType.type));
        directory = await _saver.save() ?? _somethingWentWrong;
      }
      return directory;
    } catch (e) {
      return directory;
    }
  }

  Future<String?> saveFileOnly(
      {required String name,
      required File file,
      String ext = '',
      MimeType mimeType = MimeType.other,
      String? customMimeType}) async {
    try {
      final applicationDirectory = await Helpers.getDirectory();

      return (await file.copy('$applicationDirectory/$name$ext')).path;
    } catch (e) {
      return null;
    }
  }

  /// [saveAs] This method will open a Save As File dialog where user can select the location for saving file.
  ///
  /// [name]: Name of your file.
  ///
  /// [bytes]: Encoded File for saving
  /// Or
  /// [file]: File to be saved.
  /// Or
  /// [filePath]: Path of file to be saved.
  /// Or
  /// [link]: Link of file to be saved.
  /// [LinkDetails] is a model which contains [link] & [headers]
  /// LinkDetails(
  ///   link: 'https://www.google.com',
  ///  headers: {
  ///    'your-header': 'header-value',
  ///    },
  /// ),
  ///
  /// Out of these 4 parameters, only one is required.
  ///
  /// [ext]: Extension of file.
  ///
  /// mimeType (Mainly required for web): MimeType from enum MimeType..
  ///
  Future<String?> saveAs({
    required String name,
    Uint8List? bytes,
    File? file,
    String? filePath,
    LinkDetails? link,
    required String ext,
    required MimeType mimeType,
    String? customMimeType,
  }) async {
    assert(mimeType != MimeType.custom || customMimeType != null,
        'customMimeType is required when mimeType is MimeType.custom');
    bytes = bytes ??
        await Helpers.getBytes(file: file, filePath: filePath, link: link);

    _saver = Saver(
        fileModel: FileModel(
            name: name,
            bytes: bytes,
            ext: ext,
            mimeType:
                mimeType == MimeType.custom ? customMimeType! : mimeType.type));
    String? path = await _saver.saveAs();
    return path;
  }
}
