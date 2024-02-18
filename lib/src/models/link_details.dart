// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

class LinkDetails {
  final String link;
  final String method;
  final Object? body;
  final Map<String, String>? headers;
  LinkDetails({
    required this.link,
    this.headers,
    this.body,
    this.method = 'GET',
  });

  LinkDetails copyWith({
    String? link,
    String? method,
    Object? body,
    Map<String, String>? headers,
  }) {
    return LinkDetails(
      link: link ?? this.link,
      body: body ?? this.body,
      method: method ?? this.method,
      headers: headers ?? this.headers,
    );
  }

  @override
  String toString() => 'LinkDetails(link: $link, headers: $headers)';

  @override
  bool operator ==(covariant LinkDetails other) {
    if (identical(this, other)) return true;

    return other.link == link &&
        mapEquals(other.headers, headers) &&
        other.method == method &&
        other.body == body;
  }

  @override
  int get hashCode =>
      link.hashCode ^ headers.hashCode ^ method.hashCode ^ body.hashCode;
}
