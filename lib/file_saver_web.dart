import 'dart:async';
import 'dart:convert';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart';

import 'package:file_saver/src/models/file.model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the FileSaver plugin.
class FileSaverWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'file_saver',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FileSaverWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'saveFile':
        String args = call.arguments;

        return downloadFile(FileModel.fromJson(args));
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'file_saver for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  static Future<bool> downloadFile(FileModel fileModel) async {
    bool success = false;

    try {
      String url = 'data:application/octet-stream;base64,${base64Encode(fileModel.bytes)}';
      Document htmlDocument = document;
      HTMLAnchorElement anchor = htmlDocument.createElement('a') as HTMLAnchorElement;
      anchor.href = url;
      anchor.style.display = fileModel.name + fileModel.ext;
      anchor.download = fileModel.name + fileModel.ext;
      document.body!.appendChild(anchor);
      anchor.click();
      document.body!.removeChild(anchor);
      success = true;
    } catch (e) {
      rethrow;
    }
    return success;
  }
}
