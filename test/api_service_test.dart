  import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/models/assessment_request.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/models/severity.dart';

Map<String, dynamic> _score(int score, String severity) =>
    {'score': score, 'maximum_score': 42, 'severity': severity};

Map<String, dynamic> _guidance(String severity) => {
      'severity': severity,
      'title': 'Title',
      'message': 'Message',
      'recommendation': 'Recommendation',
    };

Map<String, dynamic> _validBody() => {
      'status': 'success',
      'assessment': {
        'depression': _score(0, 'Normal'),
        'anxiety': _score(10, 'Moderate'),
        'stress': _score(34, 'Extremely Severe'),
      },
      'guidance': {
        'depression': _guidance('Normal'),
        'anxiety': _guidance('Moderate'),
        'stress': _guidance('Extremely Severe'),
      },
      'notice': 'Screening only.',
    };

const _jsonHeaders = {'content-type': 'application/json'};

ApiService _serviceReturning(int status, Object body,
    {Map<String, String> headers = _jsonHeaders}) {
  return ApiService(
    baseUrl: 'http://test.local',
    client: MockClient((_) async => http.Response(
          body is String ? body : jsonEncode(body),
          status,
          headers: headers,
        )),
  );
}

AssessmentRequest _request() => AssessmentRequest(List<int>.filled(21, 0));

void main() {
  group('AssessmentRequest', () {
    test('rejects wrong length', () {
      expect(() => AssessmentRequest(List<int>.filled(20, 0)),
          throwsArgumentError);
    });

    test('rejects values outside 0-3', () {
      expect(() => AssessmentRequest([...List<int>.filled(20, 0), 4]),
          throwsArgumentError);
    });
  });

  group('ApiService.submitAssessment', () {
    test('posts 42 responses as JSON to /api/assessments/', () async {
      late http.Request captured;
      final api = ApiService(
        baseUrl: 'http://test.local/',
        client: MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode(_validBody()), 200,
              headers: _jsonHeaders);
        }),
      );

      await api.submitAssessment(_request());

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'http://test.local/api/assessments/');
      expect(captured.headers['Content-Type'], contains('application/json'));
      expect((jsonDecode(captured.body)['responses'] as List).length, 21);
    });

    test('parses a successful response', () async {
      final result =
          await _serviceReturning(200, _validBody()).submitAssessment(_request());

      expect(result[Subscale.depression].score.severity, Severity.normal);
      expect(result[Subscale.anxiety].score.score, 10);
      expect(result[Subscale.stress].guidance.severity,
          Severity.extremelySevere);
      expect(result.notice, 'Screening only.');
    });

    test('JSON 400 -> ValidationException', () async {
      await expectLater(
        _serviceReturning(400, {'responses': ['invalid']})
            .submitAssessment(_request()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('HTML 400 (e.g. DisallowedHost) -> ServerException', () async {
      await expectLater(
        _serviceReturning(400, '<h1>Bad Request</h1>',
                headers: {'content-type': 'text/html'})
            .submitAssessment(_request()),
        throwsA(isA<ServerException>()),
      );
    });

    test('500 -> ServerException with status code', () async {
      await expectLater(
        _serviceReturning(500, {'detail': 'error'}).submitAssessment(_request()),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('malformed JSON -> InvalidResponseException', () async {
      await expectLater(
        _serviceReturning(200, 'not json').submitAssessment(_request()),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('missing guidance -> InvalidResponseException', () async {
      final body = _validBody()..remove('guidance');
      await expectLater(
        _serviceReturning(200, body).submitAssessment(_request()),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('unknown severity -> InvalidResponseException', () async {
      final body = _validBody();
      (body['assessment'] as Map)['stress'] = _score(34, 'Critical');
      await expectLater(
        _serviceReturning(200, body).submitAssessment(_request()),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('score/guidance severity mismatch -> InvalidResponseException',
        () async {
      final body = _validBody();
      (body['guidance'] as Map)['anxiety'] = _guidance('Mild');
      await expectLater(
        _serviceReturning(200, body).submitAssessment(_request()),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('connection failure -> NetworkException', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      await expectLater(
        api.submitAssessment(_request()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('slow server -> ApiTimeoutException', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        timeout: const Duration(milliseconds: 20),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200, headers: _jsonHeaders);
        }),
      );
      await expectLater(
        api.submitAssessment(_request()),
        throwsA(isA<ApiTimeoutException>()),
      );
    });
  });
}