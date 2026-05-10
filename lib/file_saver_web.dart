import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:file_saver/src/models/file.model.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart';

@JS('showSaveFilePicker')
external JSPromise<_FileSystemFileHandle> _showSaveFilePicker(JSAny options);

extension type _FileSystemFileHandle(JSObject _) implements JSObject {
  external JSPromise<_FileSystemWritableFileStream> createWritable();
}

extension type _FileSystemWritableFileStream(JSObject _)
    implements WritableStream {
  external JSPromise<JSAny?> write(JSAny chunk);
  external JSPromise<JSAny?> close();
  external JSPromise<JSAny?> abort();
}

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
      String url = URL.createObjectURL(
        Blob(
          <JSUint8Array>[fileModel.bytes.toJS].toJS,
          BlobPropertyBag(type: fileModel.mimeType),
        ),
      );

      Document htmlDocument = document;
      HTMLAnchorElement anchor =
          htmlDocument.createElement('a') as HTMLAnchorElement;
      anchor.href = url;
      anchor.style.display = 'none';
      anchor.download = fileModel.name + fileModel.fileExtension;
      document.body!.add(anchor);
      anchor.click();
      anchor.remove();
      URL.revokeObjectURL(url);
      success = true;
    } catch (e) {
      rethrow;
    }
    return success;
  }

  static bool get canSaveStream {
    return globalContext.hasProperty('showSaveFilePicker'.toJS).toDart;
  }

  static Future<bool> saveStream({
    required String name,
    required Stream<List<int>> stream,
  }) async {
    if (!canSaveStream) {
      throw UnsupportedError(
        'Streamed web saving requires the File System Access API. '
        'Use Chrome/Edge or use downloadLink for direct URL downloads.',
      );
    }

    final options = JSObject();
    options.setProperty('suggestedName'.toJS, name.toJS);

    final handle = await _showSaveFilePicker(options).toDart;
    final writable = await handle.createWritable().toDart;
    try {
      await for (final chunk in stream) {
        await writable.write(Uint8List.fromList(chunk).toJS).toDart;
      }
      await writable.close().toDart;
      return true;
    } catch (_) {
      await writable.abort().toDart;
      rethrow;
    }
  }

  static Future<bool> saveLinkStream({
    required String name,
    required LinkDetails link,
    required bool includeCredentials,
  }) async {
    if (!canSaveStream) {
      throw UnsupportedError(
        'Authenticated streamed web saving requires the File System Access API. '
        'Use Chrome/Edge, or use downloadLink with a signed URL.',
      );
    }
    if (link.method.toUpperCase() != 'GET' || link.body != null) {
      throw UnsupportedError(
        'saveLinkAsStream on web supports authenticated GET downloads only.',
      );
    }

    final options = JSObject();
    options.setProperty('suggestedName'.toJS, name.toJS);

    final headers = Headers();
    link.headers?.forEach((key, value) {
      headers.set(key, value);
    });

    final response = await window
        .fetch(
          _linkWithQuery(link).toJS,
          RequestInit(
            method: link.method,
            headers: headers,
            credentials: includeCredentials ? 'include' : 'same-origin',
          ),
        )
        .toDart;

    if (!response.ok) {
      throw Exception(
        'Download failed with HTTP ${response.status} ${response.statusText}',
      );
    }

    final body = response.body;
    if (body == null) {
      throw Exception('Download response does not contain a streamable body.');
    }

    final handle = await _showSaveFilePicker(options).toDart;
    final writable = await handle.createWritable().toDart;
    try {
      await body.pipeTo(writable).toDart;
      return true;
    } catch (_) {
      await writable.abort().toDart;
      rethrow;
    }
  }

  static bool downloadLink(String url, {String? name}) {
    Document htmlDocument = document;
    HTMLAnchorElement anchor =
        htmlDocument.createElement('a') as HTMLAnchorElement;
    anchor.href = url;
    if (name != null && name.isNotEmpty) {
      anchor.download = name;
    }
    anchor.rel = 'noopener';
    document.body!.add(anchor);
    anchor.click();
    anchor.remove();
    return true;
  }

  static String _linkWithQuery(LinkDetails link) {
    if (link.queryParameters == null || link.queryParameters!.isEmpty) {
      return link.link;
    }
    final uri = Uri.parse(link.link);
    final mergedParameters = <String, String>{
      ...uri.queryParameters,
      for (final entry in link.queryParameters!.entries)
        entry.key: entry.value.toString(),
    };
    return uri.replace(queryParameters: mergedParameters).toString();
  }
}
