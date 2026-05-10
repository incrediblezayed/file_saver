import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/saver.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';
import 'package:file_saver/src/utils/file_ops_stub.dart'
    if (dart.library.io) 'package:file_saver/src/utils/file_ops_io.dart'
    as file_ops;
import 'package:file_saver/src/utils/helpers.dart';
import 'package:file_saver/src/utils/mime_types.dart';
import 'package:file_saver/src/web_stream_saver_stub.dart'
    if (dart.library.js_interop) 'package:file_saver/src/web_stream_saver_web.dart';
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
  final PlatformHandler _platformHandler = PlatformHandler.instance;

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
    Object? file,
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
        'customMimeType is required when mimeType is MimeType.custom',
      );
    }
    String extension = includeExtension
        ? Helpers.getExtension(fileExtension: fileExtension)
        : '';
    final isFile = file != null || filePath != null;
    if (!isFile) {
      bytes =
          bytes ??
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
        directory =
            await saveFileOnly(
              name: name,
              file: file ?? filePath!,
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
            mimeType: mimeType.type.isEmpty ? customMimeType! : mimeType.type,
            includeExtension: includeExtension,
          ),
        );
        directory = await _saver.save() ?? _somethingWentWrong;
      }
      return directory;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> saveFileOnly({
    required String name,
    required Object file,
    String fileExtension = '',
    MimeType mimeType = MimeType.other,
    String? customMimeType,
  }) async {
    try {
      return file_ops.copyFileToDirectory(
        file: file,
        name: name,
        fileExtension: fileExtension,
      );
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
    Object? file,
    String? filePath,
    LinkDetails? link,
    String fileExtension = '',
    bool includeExtension = true,
    required MimeType mimeType,
    String? customMimeType,
    Dio? dioClient,
    Uint8List Function(dynamic data)? transformDioResponse,
  }) async {
    if (mimeType == MimeType.custom && customMimeType == null) {
      throw Exception(
        'customMimeType is required when mimeType is MimeType.custom',
      );
    }
    String extension = includeExtension
        ? Helpers.getExtension(fileExtension: fileExtension)
        : '';
    final sourcePath = filePath ?? file_ops.filePathFromObject(file);
    final shouldStreamFromPath = !kIsWeb && sourcePath != null;
    if (!shouldStreamFromPath) {
      bytes =
          bytes ??
          await Helpers.getBytes(
            file: file,
            filePath: filePath,
            link: link,
            dioClient: dioClient,
            transformDioResponse: transformDioResponse,
          );
    }

    _saver = Saver(
      fileModel: FileModel(
        name: name,
        bytes: bytes ?? Uint8List(0),
        fileExtension: extension,
        includeExtension: includeExtension,
        mimeType: mimeType == MimeType.custom ? customMimeType! : mimeType.type,
        sourcePath: shouldStreamFromPath ? sourcePath : null,
      ),
    );
    String? path = await _saver.saveAs();
    return path;
  }

  /// Starts a browser/system URL download without loading the file into Dart memory.
  ///
  /// This is intended for very large direct URL downloads. Web hands the URL to
  /// the browser. Android uses the system DownloadManager. Browser support for
  /// the suggested [name] depends on the URL origin and response headers.
  Future<String?> downloadLink({
    required LinkDetails link,
    String? name,
  }) async {
    if (link.method.toUpperCase() != 'GET' ||
        link.body != null ||
        link.queryParameters != null ||
        (kIsWeb && link.headers != null)) {
      throw UnsupportedError(
        'downloadLink can only hand off direct GET URLs. Web cannot include custom headers.',
      );
    }
    return _platformHandler.downloadLink(link, name: name);
  }

  /// Streams a URL response to disk while supporting request headers.
  ///
  /// This is useful when a large download requires an Authorization header or
  /// session cookies. On web it uses `fetch` plus the File System Access API,
  /// so it is limited to browsers that support user-selected writable files.
  /// Set [includeCredentials] to true to allow browser-managed cookies to be
  /// sent with the request. JavaScript cannot manually set the `Cookie` header.
  Future<String?> saveLinkAsStream({
    required String name,
    required LinkDetails link,
    String fileExtension = '',
    bool includeExtension = true,
    bool includeCredentials = true,
    MimeType mimeType = MimeType.other,
    String? customMimeType,
    Dio? dioClient,
  }) async {
    if (mimeType == MimeType.custom && customMimeType == null) {
      throw Exception(
        'customMimeType is required when mimeType is MimeType.custom',
      );
    }
    final extension = includeExtension
        ? Helpers.getExtension(fileExtension: fileExtension)
        : '';

    if (kIsWeb) {
      return saveWebLinkStream(
        name: '$name$extension',
        link: link,
        includeCredentials: includeCredentials,
      );
    }

    final dio = dioClient ?? Dio();
    final response = await dio.request<ResponseBody>(
      link.link,
      data: link.body,
      queryParameters: link.queryParameters,
      options: Options(
        method: link.method,
        headers: link.headers,
        responseType: ResponseType.stream,
      ),
    );
    return saveAsStream(
      name: name,
      stream: response.data!.stream,
      fileExtension: fileExtension,
      includeExtension: includeExtension,
      mimeType: mimeType,
      customMimeType: customMimeType,
    );
  }

  /// Writes [stream] to a temporary file, then saves from that file path.
  ///
  /// On native platforms this avoids keeping the complete file in memory. On
  /// Android, iOS, macOS, and Windows `saveAs` uses native file-path copying for
  /// the final save step. On web this uses the File System Access API when the
  /// browser supports it.
  Future<String?> saveAsStream({
    required String name,
    required Stream<List<int>> stream,
    String fileExtension = '',
    bool includeExtension = true,
    required MimeType mimeType,
    String? customMimeType,
  }) async {
    if (kIsWeb) {
      final extension = includeExtension
          ? Helpers.getExtension(fileExtension: fileExtension)
          : '';
      return saveWebStream(name: '$name$extension', stream: stream);
    }
    final extension = includeExtension
        ? Helpers.getExtension(fileExtension: fileExtension)
        : '';
    final tempFilePath = await file_ops.writeStreamToTempFile(
      stream: stream,
      extension: extension,
    );
    try {
      return await saveAs(
        name: name,
        filePath: tempFilePath,
        fileExtension: fileExtension,
        includeExtension: includeExtension,
        mimeType: mimeType,
        customMimeType: customMimeType,
      );
    } finally {
      await file_ops.deleteFile(tempFilePath);
    }
  }
}
