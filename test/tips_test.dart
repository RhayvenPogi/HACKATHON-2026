import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muni_app/core/services/api_service.dart';

void main() {
  ApiService serviceReturning(Map<String, dynamic> body, {void Function(http.Request)? onRequest}) {
    return ApiService(
      baseUrl: 'http://test.local',
      client: MockClient((req) async {
        onRequest?.call(req);
        return http.Response(jsonEncode(body), 200,
            headers: {'content-type': 'application/json'});
      }),
    );
  }

  Map<String, dynamic> body(String source) => {
        'topic': 'sleep',
        'label': 'Sleep',
        'source': source,
        'tips': [
          {'title': 'A', 'body': 'a'},
          {'title': 'B', 'body': 'b'},
          {'title': 'C', 'body': 'c'},
        ],
      };

  test('sends only the topic', () async {
    late http.Request sent;
    await serviceReturning(body('ai'), onRequest: (r) => sent = r).getTips('sleep');
    expect(sent.url.path, '/api/tips/');
    expect(jsonDecode(sent.body), {'topic': 'sleep'});
  });

  test('marks AI vs curated tips', () async {
    final ai = await serviceReturning(body('ai')).getTips('sleep');
    final curated = await serviceReturning(body('curated')).getTips('sleep');
    expect(ai.isAi, isTrue);
    expect(curated.isAi, isFalse);
    expect(ai.tips.length, 3);
  });
}