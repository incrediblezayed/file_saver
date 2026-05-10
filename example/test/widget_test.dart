import 'dart:ui';

import 'package:file_saver_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders manual test actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const FileSaverExampleApp());

    expect(find.text('File Saver Example'), findsOneWidget);
    expect(find.text('saveFile from bytes'), findsOneWidget);
    expect(find.text('Result log'), findsOneWidget);
  });
}
