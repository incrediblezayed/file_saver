import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/utils/file_ops_stub.dart'
    if (dart.library.io) 'package:file_saver/src/utils/file_ops_io.dart'
    as file_ops;
import 'package:flutter/foundation.dart';

///Helper Class for serveral utility methods
///
class Helpers {
  ///This method provides [Uint8List] from [File]
  static Future<Uint8List> _getBytesFromFile(Object file) async {
    return file_ops.readFileBytes(file);
  }

  ///This method provides [Uint8List] from file path
  static Future<Uint8List> _getBytesFromPath(String path) async {
    return file_ops.readPathBytes(path);
  }

  ///This method provides [Uint8List] from link
  ///[LinkDetails] is used to provide link and headers
  ///[Dio] is used to provide custom dio instance if needed
  ///[transformDioResponse] is used to provide custom data transformation
  ///Note: Always put the full link within the link field
  static Future<Uint8List> _getBytesFromLink(
    LinkDetails link, {
    Dio? dioClient,
    Uint8List Function(dynamic data)? transformDioResponse,
  }) async {
    final dio =
        dioClient ??
        Dio(
          BaseOptions(
            headers: link.headers,
            method: link.method,
            responseType: ResponseType.bytes,
          ),
        );
    Response response = await dio.request(
      link.link,
      data: link.body,
      queryParameters: link.queryParameters,
    );
    if (transformDioResponse != null) {
      return transformDioResponse(response.data);
    } else {
      if (response.data is Uint8List) {
        return response.data;
      } else if (response.data is List<int>) {
        return Uint8List.fromList(response.data);
      } else if (response.data is String) {
        return utf8.encode(response.data);
      } else {
        throw Exception(
          'Invalid data type, if you have a different response type, then provide the transformDioResponse function',
        );
      }
    }
  }

  ///This method provides default downloads directory for saving the file for Android, iOS, Linux, Windows, macOS
  static Future<String?> getDirectory() async {
    return file_ops.getDirectory();
  }

  static String getFilePathSlash() {
    return '/';
  }

  ///This method is used to format the extension as per the requirement
  static String getExtension({required String fileExtension}) {
    if (fileExtension.contains('.')) {
      return fileExtension;
    } else {
      if (fileExtension.isNotEmpty) {
        return '.$fileExtension';
      }
      return '';
    }
  }

  ///This method is used to get [Uint8List] from either [filePath], [link] or [file]
  static Future<Uint8List> getBytes({
    String? filePath,
    LinkDetails? link,
    Object? file,
    Dio? dioClient,
    Uint8List Function(dynamic data)? transformDioResponse,
  }) async {
    assert(
      filePath != null || link != null || file != null,
      'Either filePath or link or file must be provided',
    );
    if (filePath != null) {
      return _getBytesFromPath(filePath);
    } else {
      if (link != null) {
        return _getBytesFromLink(
          link,
          dioClient: dioClient,
          transformDioResponse: transformDioResponse,
        );
      } else if (file != null) {
        return _getBytesFromFile(file);
      } else {
        throw Exception('Either filePath or link or file must be provided');
      }
    }
  }
}
