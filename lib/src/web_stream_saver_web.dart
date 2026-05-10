import 'dart:async';

import 'package:file_saver/file_saver_web.dart';
import 'package:file_saver/src/models/link_details.dart';

Future<String?> saveWebStream({
  required String name,
  required Stream<List<int>> stream,
}) async {
  final saved = await FileSaverWeb.saveStream(name: name, stream: stream);
  return saved ? 'Downloads' : null;
}

Future<String?> saveWebLinkStream({
  required String name,
  required LinkDetails link,
  required bool includeCredentials,
}) async {
  final saved = await FileSaverWeb.saveLinkStream(
    name: name,
    link: link,
    includeCredentials: includeCredentials,
  );
  return saved ? 'Downloads' : null;
}
