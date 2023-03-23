import 'dart:developer';
import 'dart:io';

import 'package:file_saver/src/utils/mime_types.dart';
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
  static Future<Uint8List> _getBytesFromLink(String link) async {
    final httpClient = Client();
    Response response = await httpClient.get(Uri.parse(link));
    Uint8List bytes = response.bodyBytes;
    httpClient.close();
    return bytes;
  }

  ///This method provides default downloads directory for saving the file for Android, iOS, Linux, Windows, macOS
  static Future<String?> getDirectory() async {
    String? path;
    try {
      if (Platform.isIOS) {
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
      log("Something wemt worng while getting directories");
      log(e.toString());
    }
    return path;
  }

  ///This method is used to format the extension as per the requirement
  static String getExtension({required String extension}) {
    if (extension.contains('.')) {
      return extension;
    } else {
      return ".$extension";
    }
  }

  ///This method is used to get [Uint8List] from either [filePath], [link] or [file]
  static Future<Uint8List> getBytes(
      {String? filePath, String? link, File? file}) async {
    assert(filePath != null || link != null || file != null,
        "Either filePath or link or file must be provided");
    if (filePath != null) {
      return _getBytesFromPath(filePath);
    } else {
      if (link != null) {
        return _getBytesFromLink(link);
      } else if (file != null) {
        return _getBytesFromFile(file);
      } else {
        throw Exception("Either filePath or link or file must be provided");
      }
    }
  }

  ///This method will return String value of respective [MimeType]
  static String getType(MimeType type) {
    switch (type) {
      case MimeType.avi:
        return 'video/x-msvideo';
      case MimeType.aac:
        return 'audio/aac';
      case MimeType.bmp:
        return 'image/bmp';
      case MimeType.epub:
        return 'application/epub+zip';
      case MimeType.gif:
        return 'image/gif';
      case MimeType.json:
        return 'application/json';
      case MimeType.mpeg:
        return 'video/mpeg';
      case MimeType.mp3:
        return 'audio/mpeg';
      case MimeType.jpeg:
        return 'image/jpeg';
      case MimeType.otf:
        return 'font/otf';
      case MimeType.png:
        return 'image/png';
      case MimeType.openDocPresentation:
        return 'application/vnd.oasis.opendocument.presentation';
      case MimeType.openDocText:
        return 'application/vnd.oasis.opendocument.text';
      case MimeType.openDocSheets:
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case MimeType.pdf:
        return 'application/pdf';
      case MimeType.ttf:
        return 'font/ttf';
      case MimeType.zip:
        return 'application/zip';
      case MimeType.microsoftExcel:
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      case MimeType.microsoftPresentation:
        return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
      case MimeType.microsoftWord:
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      case MimeType.asice:
        return "application/vnd.etsi.asic-e+zip";
      case MimeType.asics:
        return "application/vnd.etsi.asic-s+zip";
      case MimeType.bDoc:
        return "application/vnd.etsi.asic-e+zip";
      case MimeType.other:
        return "application/octet-stream";
      case MimeType.text:
        return 'text/plain';
      case MimeType.csv:
        return 'text/csv';
      default:
        return "application/octet-stream";
    }
  }
}
