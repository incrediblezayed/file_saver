// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

/// Describes a URL to download, plus the request details needed to fetch it.
///
/// [body] may be a `String`, a `List<int>` of raw bytes, or any JSON-encodable
/// value (`Map`, `List`, …), which is sent as `application/json`.
class LinkDetails {
  final String link;
  final String method;
  final Object? body;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  LinkDetails({
    required this.link,
    this.headers,
    this.body,
    this.method = 'GET',
    this.queryParameters,
  });

  Uri get uri {
    final parsed = Uri.parse(link);
    if (queryParameters == null || queryParameters!.isEmpty) {
      return parsed;
    }
    return parsed.replace(
      queryParameters: <String, String>{
        ...parsed.queryParameters,
        for (final entry in queryParameters!.entries)
          entry.key: entry.value.toString(),
      },
    );
  }

  @override
  bool operator ==(covariant LinkDetails other) {
    if (identical(this, other)) return true;

    return other.link == link &&
        other.method == method &&
        other.body == body &&
        mapEquals(other.headers, headers) &&
        mapEquals(other.queryParameters, queryParameters);
  }

  @override
  int get hashCode {
    return link.hashCode ^
        method.hashCode ^
        body.hashCode ^
        headers.hashCode ^
        queryParameters.hashCode;
  }

  @override
  String toString() {
    return 'LinkDetails(link: $link, method: $method, body: $body, headers: $headers, queryParameters: $queryParameters)';
  }
}
