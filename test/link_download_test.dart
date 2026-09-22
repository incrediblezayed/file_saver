import 'dart:convert';
import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:file_saver/src/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LinkDetails.uri', () {
    test('merges queryParameters into an existing query string', () {
      final link = LinkDetails(
        link: 'https://example.com/file?a=1',
        queryParameters: {'b': 2, 'c': 'x y'},
      );
      expect(link.uri.queryParameters, {'a': '1', 'b': '2', 'c': 'x y'});
    });

    test('returns the link untouched without queryParameters', () {
      expect(
        LinkDetails(link: 'https://example.com/file?a=1').uri.toString(),
        'https://example.com/file?a=1',
      );
    });
  });

  group('Helpers.getBytes(link:)', () {
    test('sends method, headers, merged query and JSON body', () async {
      http.Request? seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response.bytes([1, 2, 3], 200);
      });

      final bytes = await Helpers.getBytes(
        link: LinkDetails(
          link: 'https://example.com/download',
          method: 'POST',
          headers: {'Authorization': 'Bearer t'},
          queryParameters: {'id': 7},
          body: {'k': 'v'},
        ),
        httpClient: client,
      );

      expect(bytes, [1, 2, 3]);
      expect(seen!.method, 'POST');
      expect(seen!.url.toString(), 'https://example.com/download?id=7');
      expect(seen!.headers['Authorization'], 'Bearer t');
      expect(seen!.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(seen!.body), {'k': 'v'});
    });

    test('sends a String body as-is and List<int> as raw bytes', () async {
      final bodies = <Object>[];
      final client = MockClient((request) async {
        bodies.add(request.bodyBytes);
        return http.Response('', 200);
      });

      await Helpers.getBytes(
        link: LinkDetails(link: 'https://e.com', method: 'PUT', body: 'hi'),
        httpClient: client,
      );
      await Helpers.getBytes(
        link: LinkDetails(link: 'https://e.com', method: 'PUT', body: [9, 8]),
        httpClient: client,
      );

      expect(bodies, [
        utf8.encode('hi'),
        [9, 8],
      ]);
    });

    test('throws ClientException on HTTP errors', () async {
      final client = MockClient(
        (_) async => http.Response('nope', 404, reasonPhrase: 'Not Found'),
      );

      expect(
        () => Helpers.getBytes(
          link: LinkDetails(link: 'https://example.com/missing'),
          httpClient: client,
        ),
        throwsA(
          isA<http.ClientException>().having(
            (e) => e.message,
            'message',
            'Download failed with HTTP 404 Not Found',
          ),
        ),
      );
    });

    test(
      'annotates connection failures with the macOS network entitlement',
      () async {
        final client = MockClient((_) async {
          throw http.ClientException('Connection failed');
        });

        expect(
          () => Helpers.getBytes(
            link: LinkDetails(link: 'https://example.com'),
            httpClient: client,
          ),
          throwsA(
            isA<http.ClientException>().having(
              (e) => e.message,
              'message',
              contains('com.apple.security.network.client'),
            ),
          ),
        );
      },
      skip: !Platform.isMacOS,
    );
  });
}
