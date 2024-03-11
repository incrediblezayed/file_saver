// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LinkDetails {
  final String link;
  final String method;
  final Object? body;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  final ResponseType responseType;
  LinkDetails({
    required this.link,
    this.headers,
    this.body,
    this.method = 'GET',
    this.queryParameters,
    this.responseType = ResponseType.bytes,
  });

  @override
  bool operator ==(covariant LinkDetails other) {
    if (identical(this, other)) return true;

    return other.link == link &&
        other.method == method &&
        other.body == body &&
        mapEquals(other.headers, headers) &&
        mapEquals(other.queryParameters, queryParameters) &&
        other.responseType == responseType;
  }

  @override
  int get hashCode {
    return link.hashCode ^
        method.hashCode ^
        body.hashCode ^
        headers.hashCode ^
        queryParameters.hashCode ^
        responseType.hashCode;
  }

  @override
  String toString() {
    return 'LinkDetails(link: $link, method: $method, body: $body, headers: $headers, queryParameters: $queryParameters, responseType: $responseType)';
  }
}
