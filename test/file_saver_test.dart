import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('file_saver');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return '/saved/path';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // saveAs only goes through the method channel on these hosts; Linux throws
  // UnimplementedError before reaching it.
  final hasNativeSaveAs =
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isAndroid ||
      Platform.isIOS;

  group('saveAs', () {
    test('forwards initialDirectory and dialogTitle to the platform', () async {
      await FileSaver.instance.saveAs(
        name: 'report',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'txt',
        mimeType: MimeType.text,
        initialDirectory: '/Users/me/Documents',
        dialogTitle: 'Export report',
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'saveAs');
      final args = Map<String, dynamic>.from(calls.single.arguments as Map);
      expect(args['name'], 'report');
      expect(args['fileExtension'], '.txt');
      expect(args['initialDirectory'], '/Users/me/Documents');
      expect(args['dialogTitle'], 'Export report');
    }, skip: !hasNativeSaveAs);

    test('sends null dialog options when not provided', () async {
      await FileSaver.instance.saveAs(
        name: 'report',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: MimeType.text,
      );

      final args = Map<String, dynamic>.from(calls.single.arguments as Map);
      expect(args['initialDirectory'], isNull);
      expect(args['dialogTitle'], isNull);
      expect(args['fileExtension'], '');
    }, skip: !hasNativeSaveAs);
  });
}
