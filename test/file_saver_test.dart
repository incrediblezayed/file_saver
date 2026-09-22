import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:file_saver/src/messages.g.dart';
import 'package:file_saver/src/platform_handler/platform_handler_all.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Records every call instead of talking to a platform channel.
class _FakeHostApi extends FileSaverHostApi {
  final saveAsCalls = <SaveRequest>[];
  final galleryCalls = <SaveRequest>[];

  @override
  Future<String?> saveFile(SaveRequest request) async => '/app/${request.name}';

  @override
  Future<String?> saveAs(SaveRequest request) async {
    saveAsCalls.add(request);
    return '/saved/path';
  }

  @override
  Future<String?> saveToGallery(SaveRequest request) async {
    galleryCalls.add(request);
    return 'content://media/1';
  }

  @override
  Future<String> downloadLink(DownloadRequest request) async => '1';
}

/// Points path_provider at a temp directory so desktop saves are observable.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.directory);
  final String directory;

  @override
  Future<String?> getDownloadsPath() async => directory;

  @override
  Future<String?> getApplicationDocumentsPath() async => directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHostApi api;

  setUp(() {
    api = _FakeHostApi();
    PlatformHandlerAll.hostApiOverride = api;
  });

  tearDown(() {
    PlatformHandlerAll.hostApiOverride = null;
  });

  // saveAs reaches the host API on these hosts; Linux throws first.
  final hasNativeSaveAs =
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isAndroid ||
      Platform.isIOS;

  group('saveToGallery', () {
    test('rejects mime types that are not image or video', () {
      expect(
        () => FileSaver.instance.saveToGallery(
          name: 'doc',
          bytes: Uint8List.fromList([1]),
          mimeType: MimeType.pdf,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(api.galleryCalls, isEmpty);
    });

    test('throws UnsupportedError on desktop hosts', () {
      expect(
        () => FileSaver.instance.saveToGallery(
          name: 'pic',
          bytes: Uint8List.fromList([1]),
          mimeType: MimeType.png,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    }, skip: !(Platform.isMacOS || Platform.isWindows || Platform.isLinux));
  });

  group('saveToDownloads', () {
    test('rejects a subfolder that is a path', () {
      expect(
        () => FileSaver.instance.saveToDownloads(
          name: 'report',
          bytes: Uint8List.fromList([1]),
          subfolder: '../escape',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('desktop: writes into Downloads/<subfolder>', () async {
      final downloads = await Directory.systemTemp.createTemp('file_saver_dl');
      addTearDown(() => downloads.delete(recursive: true));
      PathProviderPlatform.instance = _FakePathProvider(downloads.path);

      final path = await FileSaver.instance.saveToDownloads(
        name: 'report',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'txt',
        subfolder: 'My App',
      );

      expect(path, '${downloads.path}/My App/report.txt');
      expect(await File(path!).readAsBytes(), [1, 2, 3]);
      expect(api.galleryCalls, isEmpty);
    }, skip: !(Platform.isMacOS || Platform.isWindows || Platform.isLinux));

    test('desktop: copies from filePath without loading bytes', () async {
      final downloads = await Directory.systemTemp.createTemp('file_saver_dl');
      addTearDown(() => downloads.delete(recursive: true));
      PathProviderPlatform.instance = _FakePathProvider(downloads.path);
      final source = File('${downloads.path}/source.bin');
      await source.writeAsBytes([7, 8, 9]);

      final path = await FileSaver.instance.saveToDownloads(
        name: 'copy',
        filePath: source.path,
        fileExtension: 'bin',
      );

      expect(await File(path!).readAsBytes(), [7, 8, 9]);
    }, skip: !(Platform.isMacOS || Platform.isWindows || Platform.isLinux));
  });

  group('saveAs', () {
    test('forwards initialDirectory and dialogTitle to the platform', () async {
      final path = await FileSaver.instance.saveAs(
        name: 'report',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'txt',
        mimeType: MimeType.text,
        initialDirectory: '/Users/me/Documents',
        dialogTitle: 'Export report',
      );

      expect(path, '/saved/path');
      final request = api.saveAsCalls.single;
      expect(request.name, 'report');
      expect(request.fileExtension, '.txt');
      expect(request.bytes, [1, 2, 3]);
      expect(request.sourcePath, isNull);
      expect(request.initialDirectory, '/Users/me/Documents');
      expect(request.dialogTitle, 'Export report');
    }, skip: !hasNativeSaveAs);

    test('sends null dialog options when not provided', () async {
      await FileSaver.instance.saveAs(
        name: 'report',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: MimeType.text,
      );

      final request = api.saveAsCalls.single;
      expect(request.initialDirectory, isNull);
      expect(request.dialogTitle, isNull);
      expect(request.fileExtension, '');
    }, skip: !hasNativeSaveAs);

    test('streams from filePath without loading bytes', () async {
      final file = File(
        '${Directory.systemTemp.path}/file_saver_test_${DateTime.now().microsecondsSinceEpoch}.bin',
      );
      await file.writeAsBytes([9, 9, 9]);
      addTearDown(() => file.delete());

      await FileSaver.instance.saveAs(
        name: 'big',
        filePath: file.path,
        mimeType: MimeType.other,
      );

      final request = api.saveAsCalls.single;
      expect(request.sourcePath, file.path);
      expect(request.bytes, isNull);
    }, skip: !hasNativeSaveAs);
  });
}
