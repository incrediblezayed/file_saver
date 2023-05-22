// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class LinkDetails {
  final String link;
  final Map<String, String>? headers;
  LinkDetails({
    required this.link,
    this.headers,
  });

  LinkDetails copyWith({
    String? link,
    Map<String, String>? headers,
  }) {
    return LinkDetails(
      link: link ?? this.link,
      headers: headers ?? this.headers,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'link': link,
      'headers': headers,
    };
  }

  factory LinkDetails.fromMap(Map<String, dynamic> map) {
    return LinkDetails(
      link: map['link'] as String,
      headers: map['headers'] as Map<String, String>?,
    );
  }

  String toJson() => json.encode(toMap());

  factory LinkDetails.fromJson(String source) =>
      LinkDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'LinkDetails(link: $link, headers: $headers)';

  @override
  bool operator ==(covariant LinkDetails other) {
    if (identical(this, other)) return true;

    return other.link == link && mapEquals(other.headers, headers);
  }

  @override
  int get hashCode => link.hashCode ^ headers.hashCode;
}
