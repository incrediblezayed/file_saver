import 'dart:async';

import 'package:file_saver/src/models/link_details.dart';

Future<String?> saveWebStream({
  required String name,
  required Stream<List<int>> stream,
}) {
  throw UnsupportedError('Streamed web saving is only available on web.');
}

Future<String?> saveWebLinkStream({
  required String name,
  required LinkDetails link,
  required bool includeCredentials,
}) {
  throw UnsupportedError('Streamed web link saving is only available on web.');
}
