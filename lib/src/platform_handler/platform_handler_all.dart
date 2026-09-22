import 'dart:developer';
import 'dart:io';

import 'package:file_saver/src/messages.g.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:file_saver/src/platform_handler/platform_handler.dart';
import 'package:file_saver/src/utils/helpers.dart';
import 'package:flutter/foundation.dart';

PlatformHandler getPlatformHandler() {
  return PlatformHandlerAll();
}

class PlatformHandlerAll extends PlatformHandler {
  @visibleForTesting
  static FileSaverHostApi? hostApiOverride;

  final FileSaverHostApi _api = hostApiOverride ?? FileSaverHostApi();

  final String _issueLink =
      'https://www.github.com/incrediblezayed/file_saver/issues';

  Future<String> saveFileForOtherPlatforms(SaveRequest request) async {
    final base = await Helpers.getDirectory() ?? '';
    if (base == '') {
      log(
        'The path was found null or empty, please report the issue at $_issueLink',
      );
      throw Exception('The path was found null or empty');
    }
    final slash = Helpers.getFilePathSlash();
    var directory = base;
    final folder = request.folder?.trim();
    if (folder != null && folder.isNotEmpty) {
      directory = '$base$slash$folder';
      await Directory(directory).create(recursive: true);
    }
    final File file = File(
      '$directory$slash${request.name}${request.fileExtension}',
    );
    try {
      final sourcePath = request.sourcePath;
      if (sourcePath != null) {
        await File(sourcePath).copy(file.path);
      } else {
        await file.writeAsBytes(
          request.bytes ?? (throw ArgumentError('bytes is null')),
        );
      }
    } on FileSystemException catch (e) {
      if (Platform.isMacOS) {
        throw FileSystemException(
          '${e.message}. On macOS, writing to Downloads from a sandboxed app '
          'requires the com.apple.security.files.downloads.read-write '
          'entitlement (see README).',
          e.path,
          e.osError,
        );
      }
      rethrow;
    }
    return file.path;
  }

  @override
  Future<String?> saveFile(SaveRequest request) async {
    if (Platform.isAndroid) {
      return _api.saveFile(request);
    }
    return saveFileForOtherPlatforms(request);
  }

  ///Open File Manager
  @override
  Future<String?> saveAs(SaveRequest request) async {
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows) {
      return _api.saveAs(request);
    }
    throw UnimplementedError('Unimplemented Error');
  }

  @override
  Future<String?> saveToDownloads(SaveRequest request) {
    if (Platform.isAndroid) {
      return _api.saveToDownloads(request);
    }
    if (Platform.isIOS) {
      throw UnsupportedError(
        'iOS has no shared Downloads folder. Use saveFile (app Documents, '
        'visible in the Files app) or saveAs.',
      );
    }
    return saveFileForOtherPlatforms(request);
  }

  @override
  Future<String?> saveToGallery(SaveRequest request) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'saveToGallery is only supported on Android and iOS.',
      );
    }
    return _api.saveToGallery(request);
  }

  @override
  Future<String?> downloadLink(LinkDetails link, {String? name}) async {
    if (Platform.isAndroid) {
      return _api.downloadLink(
        DownloadRequest(url: link.link, name: name, headers: link.headers),
      );
    }
    throw UnsupportedError(
      'downloadLink is only supported on Android and web. Use saveFile/saveAs with filePath for other native streamed writes.',
    );
  }
}
