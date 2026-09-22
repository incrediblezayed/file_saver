import 'dart:convert';

import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/utils/file_ops_stub.dart'
    if (dart.library.io) 'package:file_saver/src/utils/file_ops_io.dart'
    as file_ops;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  ///[LinkDetails] is used to provide link, method, headers, body and query
  ///[httpClient] is used to provide a custom client (proxies, retries, cookies)
  ///Note: Always put the full link within the link field
  static Future<Uint8List> _getBytesFromLink(
    LinkDetails link, {
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    try {
      final response = await http.Response.fromStream(
        await sendRequest(client, link),
      );
      return response.bodyBytes;
    } finally {
      if (httpClient == null) client.close();
    }
  }

  /// Sends [link] with [client] and returns the streamed response.
  ///
  /// Throws [http.ClientException] for HTTP 4xx/5xx so callers never write an
  /// error page to disk. On macOS a connection failure is annotated with the
  /// sandbox entitlement that is usually missing.
  static Future<http.StreamedResponse> sendRequest(
    http.Client client,
    LinkDetails link,
  ) async {
    final request = http.Request(link.method, link.uri);
    link.headers?.forEach((key, value) => request.headers[key] = value);
    _applyBody(request, link.body);

    final http.StreamedResponse response;
    try {
      response = await client.send(request);
    } on http.ClientException catch (e) {
      if (file_ops.isMacOS) {
        throw http.ClientException(
          '${e.message}. On macOS, network access from a sandboxed app requires '
          'the com.apple.security.network.client entitlement (see README).',
          e.uri,
        );
      }
      rethrow;
    }
    if (response.statusCode >= 400) {
      throw http.ClientException(
        'Download failed with HTTP ${response.statusCode} '
                '${response.reasonPhrase ?? ''}'
            .trim(),
        link.uri,
      );
    }
    return response;
  }

  static void _applyBody(http.Request request, Object? body) {
    if (body == null) return;
    if (body is String) {
      request.body = body;
    } else if (body is List<int>) {
      request.bodyBytes = body;
    } else {
      request.headers.putIfAbsent(
        'content-type',
        () => 'application/json; charset=utf-8',
      );
      request.body = jsonEncode(body);
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
    http.Client? httpClient,
  }) async {
    assert(
      filePath != null || link != null || file != null,
      'Either filePath or link or file must be provided',
    );
    if (filePath != null) {
      return _getBytesFromPath(filePath);
    } else {
      if (link != null) {
        return _getBytesFromLink(link, httpClient: httpClient);
      } else if (file != null) {
        return _getBytesFromFile(file);
      } else {
        throw Exception('Either filePath or link or file must be provided');
      }
    }
  }
}
