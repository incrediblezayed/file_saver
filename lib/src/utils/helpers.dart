import 'dart:developer';
import 'dart:io';

import 'package:file_saver/src/models/link_details.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider_linux/path_provider_linux.dart'
    as path_provider_linux;
import 'package:path_provider_windows/path_provider_windows.dart'
    as path_provder_windows;

///Helper Class for serveral utility methods
///
class Helpers {
  ///This method provides [Uint8List] from [File]
  static Future<Uint8List> _getBytesFromFile(File file) async {
    return await file.readAsBytes();
  }

  ///This method provides [Uint8List] from file path
  static Future<Uint8List> _getBytesFromPath(String path) async {
    File file = File(path);
    return await file.readAsBytes();
  }

  ///This method provides [Uint8List] from link
  static Future<Uint8List> _getBytesFromLink(LinkDetails link) async {
    final httpClient = Client();
    Response response = await httpClient.get(
      Uri.parse(link.link),
      headers: link.headers,
    );
    Uint8List bytes = response.bodyBytes;
    httpClient.close();
    return bytes;
  }

  ///This method provides default downloads directory for saving the file for Android, iOS, Linux, Windows, macOS
  static Future<String?> getDirectory() async {
    String? path;
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        path = (await path_provider.getApplicationDocumentsDirectory()).path;
      } else if (Platform.isMacOS) {
        path = (await path_provider.getDownloadsDirectory())?.path;
      } else if (Platform.isWindows) {
        path_provder_windows.PathProviderWindows pathWindows =
            path_provder_windows.PathProviderWindows();
        path = await pathWindows.getDownloadsPath();
      } else if (Platform.isLinux) {
        path_provider_linux.PathProviderLinux pathLinux =
            path_provider_linux.PathProviderLinux();
        path = await pathLinux.getDownloadsPath();
      }
    } on Exception catch (e) {
      log('Something wemt worng while getting directories');
      log(e.toString());
    }
    return path;
  }

  ///This method is used to format the extension as per the requirement
  static String getExtension({required String extension}) {
    if (extension.contains('.')) {
      return extension;
    } else {
      if (extension.isNotEmpty) {
        return '.$extension';
      }
      return '';
    }
  }

  ///This method is used to get [Uint8List] from either [filePath], [link] or [file]
  static Future<Uint8List> getBytes(
      {String? filePath, LinkDetails? link, File? file}) async {
    assert(filePath != null || link != null || file != null,
        'Either filePath or link or file must be provided');
    if (filePath != null) {
      return _getBytesFromPath(filePath);
    } else {
      if (link != null) {
        return _getBytesFromLink(link);
      } else if (file != null) {
        return _getBytesFromFile(file);
      } else {
        throw Exception('Either filePath or link or file must be provided');
      }
    }
  }
}
