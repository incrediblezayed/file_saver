import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
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
  /// [fileExtension]: Extension of file.
  ///
  /// [includeExtension]: Whether to include the extension in the saved file name. Defaults to true.
  /// Set to false to save files without extension (e.g., "myfile" instead of "myfile.txt").
  ///
  /// mimeType (Mainly required for web): MimeType from enum MimeType..
  ///
  /// More Mimetypes will be added in future
  Future<String> saveFile({
    required String name,
    Uint8List? bytes,
    File? file,
    String? filePath,
    LinkDetails? link,
    String fileExtension = '',
    bool includeExtension = true,
    MimeType mimeType = MimeType.other,
    String? customMimeType,
    Dio? dioClient,
    Uint8List Function(dynamic data)? transformDioResponse,
  }) async {
    if (mimeType == MimeType.custom && customMimeType == null) {
      throw Exception(
          'customMimeType is required when mimeType is MimeType.custom');
    }
    String extension = includeExtension
        ? Helpers.getExtension(fileExtension: fileExtension)
        : '';
    final isFile = file != null || filePath != null;
    if (!isFile) {
      bytes = bytes ??
          await Helpers.getBytes(
            file: file,
            filePath: filePath,
            link: link,
            dioClient: dioClient,
            transformDioResponse: transformDioResponse,
          );
    }
    try {
      if (isFile) {
        directory = await saveFileOnly(
              name: name,
              file: file ?? File(filePath!),
              fileExtension: extension,
              mimeType: mimeType,
            ) ??
            _somethingWentWrong;
      } else {
        _saver = Saver(
            fileModel: FileModel(
                name: name,
                bytes: bytes!,
                fileExtension: extension,
                mimeType:
                    mimeType.type.isEmpty ? customMimeType! : mimeType.type,
                includeExtension: includeExtension));
        directory = await _saver.save() ?? _somethingWentWrong;
      }
      return directory;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> saveFileOnly(
      {required String name,
      required File file,
      String fileExtension = '',
      MimeType mimeType = MimeType.other,
      String? customMimeType}) async {
    try {
      final applicationDirectory = await Helpers.getDirectory();

      return (await file.copy('$applicationDirectory/$name$fileExtension'))
          .path;
    } catch (e) {
      rethrow;
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
  /// [fileExtension]: Extension of file.
  ///
  /// [includeExtension]: Whether to include the extension in the saved file name. Defaults to true.
  /// Set to false to save files without extension (e.g., "myfile" instead of "myfile.txt").
  ///
  /// mimeType (Mainly required for web): MimeType from enum MimeType..
  ///
  Future<String?> saveAs({
    required String name,
    Uint8List? bytes,
    File? file,
    String? filePath,
    LinkDetails? link,
    required String fileExtension,
    bool includeExtension = true,
    required MimeType mimeType,
    String? customMimeType,
    Dio? dioClient,
    Uint8List Function(dynamic data)? transformDioResponse,
  }) async {
    if (mimeType == MimeType.custom && customMimeType == null) {
      throw Exception(
          'customMimeType is required when mimeType is MimeType.custom');
    }
    String extension = includeExtension
        ? Helpers.getExtension(fileExtension: fileExtension)
        : '';
    bytes = bytes ??
        await Helpers.getBytes(
          file: file,
          filePath: filePath,
          link: link,
          dioClient: dioClient,
          transformDioResponse: transformDioResponse,
        );

    _saver = Saver(
        fileModel: FileModel(
            name: name,
            bytes: bytes,
            fileExtension: extension,
            includeExtension: includeExtension,
            mimeType:
                mimeType == MimeType.custom ? customMimeType! : mimeType.type));
    String? path = await _saver.saveAs();
    return path;
  }
}
