import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path_provider_linux/path_provider_linux.dart'
    as pathProviderLinux;
import 'package:path_provider_windows/path_provider_windows.dart'
    as pathProvderWindows;

enum MimeType {
  AVI,
  BMP,
  EPUB,
  GIF,
  JSON,
  MPEG,
  MP3,
  OTF,
  PNG,
  ZIP,
  TTF,
  RAR,
  JPEG,
  AAC,
  PDF,
  OPENDOCSHEETS,
  OPENDOCPRESENTATION,
  OPENDOCTEXT,
  MICROSOFTWORD,
  MICROSOFTEXCEL,
  MICROSOFTPRESENTATION,
  TEXT,
  CSV,
  OTHER
}

class FileSaver {
  static const MethodChannel _channel = const MethodChannel('file_saver');
  static FileSaver get instance => FileSaver();

  String _getType(MimeType type) {
    switch (type) {
      case MimeType.AVI:
        return 'video/x-msvideo';
      case MimeType.AAC:
        return 'audio/aac';
      case MimeType.BMP:
        return 'image/bmp';
      case MimeType.EPUB:
        return 'application/epub+zip';
      case MimeType.GIF:
        return 'image/gif';
      case MimeType.JSON:
        return 'application/json';
      case MimeType.MPEG:
        return 'video/mpeg';
      case MimeType.MP3:
        return 'audio/mpeg';
      case MimeType.JPEG:
        return 'image/jpeg';
      case MimeType.OTF:
        return 'font/otf';
      case MimeType.PNG:
        return 'image/png';
      case MimeType.OPENDOCPRESENTATION:
        return 'application/vnd.oasis.opendocument.presentation';
      case MimeType.OPENDOCTEXT:
        return 'application/vnd.oasis.opendocument.text';
      case MimeType.OPENDOCSHEETS:
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case MimeType.PDF:
        return 'application/pdf';
      case MimeType.TTF:
        return 'font/ttf';
      case MimeType.ZIP:
        return 'application/zip';
      case MimeType.MICROSOFTEXCEL:
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      case MimeType.MICROSOFTPRESENTATION:
        return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
      case MimeType.MICROSOFTWORD:
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      case MimeType.OTHER:
        return "application/octet-stream";
      case MimeType.TEXT:
        return 'text/plain';
      case MimeType.CSV:
        return 'text/csv';
      default:
        return "application/octet-stream";
    }
  }

  ///name: Name of your file.
  ///
  /// bytes: Encoded File for saving.
  ///
  /// ext: Extension of file.
  ///
  /// mimeType (Mainly required for web): MimeType from enum MimeType..
  ///
  /// More Mimetypes will be added in future
  Future<void> saveFile(String name, Uint8List bytes, String ext,
      {MimeType mimeType = MimeType.OTHER}) async {
    String mime = _getType(mimeType);
    try {
      if (kIsWeb) {
        Map<String, dynamic> data = <String, dynamic>{
          "bytes": bytes,
          "name": name,
          "ext": ext,
          "type": mime
        };
        String args = json.encode(data);
        await _channel.invokeMethod<void>('saveFile', args);
      } else if (Platform.isAndroid) {
        Directory directory = (await path.getExternalStorageDirectory()
            as FutureOr<Directory>) as Directory;
        final String filePath = directory.path + '/' + name + '.' + ext;
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
        bool exist = await file.exists();
        if (exist) {
          print("File saved at: ${file.path}");
        }
      } else if (Platform.isIOS) {
        final Directory iosDir = await path.getApplicationDocumentsDirectory();
        final String filePath = iosDir.path + '/' + name + '.' + ext;
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
        bool exist = await file.exists();
        if (exist) {
          print("File saved at: ${file.path}");
        }
      } else if (Platform.isMacOS) {
        final Directory macDir =
            await (path.getDownloadsDirectory() as FutureOr<Directory>);
        final String filePath = macDir.path + '/' + name + '.' + ext;
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
        bool exist = await file.exists();
        if (exist) {
          print("File saved at: ${file.path}");
        }
      } else if (Platform.isWindows) {
        _channel.invokeListMethod('saveFile');
        pathProvderWindows.PathProviderWindows pathWindows =
            pathProvderWindows.PathProviderWindows();
        String? path = await pathWindows.getDownloadsPath();
        final String filePath = path! + '/' + name + '.' + ext;
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
        bool exist = await file.exists();
        if (exist) {
          print("File saved at: ${file.path}");
        }
      } else if (Platform.isLinux) {
        pathProviderLinux.PathProviderLinux pathLinux =
            pathProviderLinux.PathProviderLinux();
        String? path = await pathLinux.getDownloadsPath();
        final String filePath = path! + '/' + name + '.' + ext;
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
        bool exist = await file.exists();
        if (exist) {
          print("File saved at: ${file.path}");
        }
      } else {
        throw UnimplementedError(
            "Sorry but the plugin only supports web, ios and android");
      }
    } catch (e) {
      print(e);
    }
  }
}
