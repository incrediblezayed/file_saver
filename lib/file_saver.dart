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

///[MimeType] is an enum for adding filetype for HTML Blob
enum MimeType {
  ///[AVI] for .avi extension
  AVI,

  ///[BMP] for .bmp extension
  BMP,

  ///[EPUB] for .epub extention
  EPUB,

  ///[GIF] for .gif extension
  GIF,

  ///[JSON] for .json extension
  JSON,

  ///[MPEG] for .mpeg extension
  MPEG,

  ///[MP3] for .mp3 extension
  MP3,

  ///[OTF] for .otf extension
  OTF,

  ///[PNG] for .png extension
  PNG,

  ///[ZIP] for .zip extension
  ZIP,

  ///[TTF] for .ttf extension
  TTF,

  ///[RAR] for .rar extension
  RAR,

  ///[JPEG] for .jpeg extension
  JPEG,

  ///[AAC] for .aac extension
  AAC,

  ///[PDF] for .pdf extension
  PDF,

  ///[OPENDOCSHEETS] for .ods extension
  OPENDOCSHEETS,

  ///[OPENDOCPRESENTATION] for .odp extension
  OPENDOCPRESENTATION,

  ///[OPENDOCTEXT] for .odt extension
  OPENDOCTEXT,

  ///[MICROSOFTWORD] for .docx extension
  MICROSOFTWORD,

  ///[MICROSOFTEXCEL] for .xlsx extension
  MICROSOFTEXCEL,

  ///[MICROSOFTPRESENTATION] for .pptx extension
  MICROSOFTPRESENTATION,

  ///[TEXT] for .txt extension
  TEXT,

  ///[CSV] for .csv extension
  CSV,

  ///[ASICE] for .asice
  ASICE,

  ///[ASICS] for .asice
  ASICS,

  ///[BDOC] for .asice
  BDOC,

  ///[OTHER] for other extension
  OTHER
}

class FileSaver {
  static const MethodChannel _channel = const MethodChannel('file_saver');

  String _somethingWentWrong =
      "Something went wrong, please report the issue https://www.github.com/incrediblezayed/file_saver/issues";
  String _issueLink =
      "https://www.github.com/incrediblezayed/file_saver/issues";

  String _saveFile = "saveFile";
  String _saveAs = "saveAs";

  ///instance of file saver
  static FileSaver get instance => FileSaver();

  ///This method will return String value of respective [MimeType]
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
      case MimeType.ASICE:
        return "application/vnd.etsi.asic-e+zip";
      case MimeType.ASICS:
        return "application/vnd.etsi.asic-s+zip";
      case MimeType.BDOC:
        return "application/vnd.etsi.asic-e+zip";
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

  ///This method provides [Directory] for the file for Android, iOS, Linux, Windows, macOS
  Future<String?> _getDirectory() async {
    String? _path = "";
    try {
      if (Platform.isIOS) {
        _path = (await path.getApplicationDocumentsDirectory()).path;
      } else if (Platform.isMacOS) {
        _path = (await path.getDownloadsDirectory())?.path;
      } else if (Platform.isWindows) {
        pathProvderWindows.PathProviderWindows pathWindows =
            pathProvderWindows.PathProviderWindows();
        _path = await pathWindows.getDownloadsPath();
      } else if (Platform.isLinux) {
        pathProviderLinux.PathProviderLinux pathLinux =
            pathProviderLinux.PathProviderLinux();
        _path = await pathLinux.getDownloadsPath();
      }
    } on Exception catch (e) {
      print("Something wemt worng while getting directories");
      print(e);
    }
    return _path;
  }

  ///Open File Manager
  Future<String> _openFileManager(Map<dynamic, dynamic> args) async {
    String? _path = "Path: None";
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _path = await _channel.invokeMethod<String>(_saveAs, args);
    } else {
      throw UnimplementedError("Unimplemented Error");
    }
    return _path!;
  }

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
  Future<String> saveFile(String name, Uint8List bytes, String ext,
      {MimeType mimeType = MimeType.OTHER}) async {
    String mime = _getType(mimeType);
    String _directory = _somethingWentWrong;
    try {
      if (kIsWeb) {
        Map<String, dynamic> data = <String, dynamic>{
          "bytes": bytes,
          "name": name,
          "ext": ext,
          "type": mime
        };
        String args = json.encode(data);
        bool? downloaded = await _channel.invokeMethod<bool>(_saveFile, args);
        if (downloaded!) {
          _directory = "Downloads";
        }
      } else if (Platform.isAndroid) {
        Map<String, dynamic> data = <String, dynamic>{
          "bytes": bytes,
          "name": name + (ext == "" ? ext : ("."+ext)),
        };
        _directory = await _channel.invokeMethod<String>(_saveFile, data) ?? "";
      } else {
        String _path = "";
        _path = await _getDirectory() ?? "";
        if (_path == "") {
          print(
              "The path was found null or empty, please report the issue at " +
                  _issueLink);
        } else {
          String filePath = _path + '/' + name + (ext == "" ? ext : ("."+ext));
          final File _file = File(filePath);
          await _file.writeAsBytes(bytes);
          bool _exist = await _file.exists();
          if (_exist) {
            _directory = _file.path;
          } else {
            print("File was not created");
          }
        }
      }
      return _directory;
    } catch (e) {
      return _directory;
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
  Future<String> saveAs(
      String name, Uint8List bytes, String ext, MimeType mimeType) async {
    String _mimeType = _getType(mimeType);
    Map<dynamic, dynamic> data = {
      'name': name,
      'ext': ext,
      'bytes': bytes,
      'type': _mimeType
    };
    String _path = await _openFileManager(data);
    return _path;
  }
}
