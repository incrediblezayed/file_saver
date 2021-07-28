import 'dart:async';
import 'dart:convert';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

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
        Map<String, dynamic> data = json.decode(args);
        List<dynamic> bytes = data['bytes'];
        Uint8List uint8list = Uint8List.fromList(List<int>.from(bytes));
        return downloadFile(
          uint8list,
          data['name'],
          data['type'],
        );
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'file_saver for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  Future<bool> downloadFile(Uint8List bytes, String name, String type) async {
    bool _success = false;

    try {
      String _url = Url.createObjectUrlFromBlob(Blob([bytes], type));
      HtmlDocument htmlDocument = document;
      AnchorElement anchor = htmlDocument.createElement('a') as AnchorElement;
      anchor.href = _url;
      anchor.style.display = name;
      anchor.download = name;
      document.body!.children.add(anchor);
      anchor.click();
      document.body!.children.remove(anchor);
      _success = true;
    } catch (e) {
      print(e);
    }
    return _success;
  }
}
