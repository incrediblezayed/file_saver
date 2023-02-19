import 'dart:developer';
import 'dart:io';

import 'package:file_saver/src/utils/mime_types.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider_linux/path_provider_linux.dart'
    as path_provider_linux;
import 'package:path_provider_windows/path_provider_windows.dart'
    as path_provder_windows;

class Helpers {
  static Future<Uint8List> getBytesFromFile(File file) async {
    return await file.readAsBytes();
  }

  static Future<Uint8List> getBytesFromPath(String path) async {
    File file = File(path);
    return await file.readAsBytes();
  }

  static Future<Uint8List> getBytesFromLink(String link) async {
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(link));
    HttpClientResponse response = await request.close();
    Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    httpClient.close();
    return bytes;
  }

  ///This method provides [Directory] for the file for Android, iOS, Linux, Windows, macOS
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

  static String getExtension({required String extension}) {
    if (extension.contains('.')) {
      return extension;
    } else {
      return ".$extension";
    }
  }

  static Future<Uint8List> getBytes(
      {String? filePath, String? link, File? file}) async {
    assert(filePath != null || link != null || file != null,
        "Either filePath or link or file must be provided");
    if (kIsWeb && filePath == null && file == null) {
      throw UnimplementedError(
          "Web doesn't support saving file from link, will be adding support soon ;)");
    }
    if (filePath != null) {
      return getBytesFromPath(filePath);
    } else {
      if (link != null) {
        return getBytesFromLink(link);
      } else if (file != null) {
        return getBytesFromFile(file);
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
