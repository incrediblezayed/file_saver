import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:file_saver/src/messages.g.dart';
import 'package:file_saver/src/models/link_details.dart';
import 'dart:typed_data';

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
    // Web is implemented in Dart and called directly; nothing to register.
  }

  static Future<bool> downloadFile(SaveRequest request) async {
    bool success = false;

    try {
      String url = URL.createObjectURL(
        Blob(
          <JSUint8Array>[(request.bytes ?? Uint8List(0)).toJS].toJS,
          BlobPropertyBag(type: request.mimeType),
        ),
      );

      Document htmlDocument = document;
      HTMLAnchorElement anchor =
          htmlDocument.createElement('a') as HTMLAnchorElement;
      anchor.href = url;
      anchor.style.display = 'none';
      anchor.download = request.name + request.fileExtension;
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

    final handle = await _pickSaveFile(options);
    if (handle == null) return false;
    final writable = await handle.createWritable().toDart;
    try {
      await for (final chunk in stream) {
        final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        await writable.write(bytes.toJS).toDart;
      }
      await writable.close().toDart;
      return true;
    } catch (_) {
      await _abort(writable);
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
          link.uri.toString().toJS,
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

    final handle = await _pickSaveFile(options);
    if (handle == null) return false;
    final writable = await handle.createWritable().toDart;
    try {
      await body.pipeTo(writable).toDart;
      return true;
    } catch (_) {
      await _abort(writable);
      rethrow;
    }
  }

  /// Shows the picker; null when the user cancels, like the other platforms.
  static Future<_FileSystemFileHandle?> _pickSaveFile(JSObject options) async {
    try {
      return await _showSaveFilePicker(options).toDart;
    } catch (error) {
      if (_isAbortError(error)) return null;
      rethrow;
    }
  }

  static bool _isAbortError(Object error) {
    // dart2js hands us the DOMException itself; the toString fallback covers
    // dart2wasm, which wraps it. Neither path can throw.
    // ignore: invalid_runtime_check_with_js_interop_types
    if (error is JSObject) {
      final name = error.getProperty<JSAny?>('name'.toJS);
      if (name.isA<JSString>()) {
        return (name as JSString).toDart == 'AbortError';
      }
    }
    return error.toString().contains('AbortError');
  }

  /// Discards the partial file without masking the error that got us here.
  static Future<void> _abort(_FileSystemWritableFileStream writable) async {
    try {
      await writable.abort().toDart;
    } catch (_) {}
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
}
