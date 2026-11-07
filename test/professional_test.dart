import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/features/professional/data/professional_session_store.dart';
import 'package:muni_app/features/professional/data/share_qr_payload.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/models/professional_session.dart';

const _token = 'AbCdEfGhIjKlMnOpQrStUvWxYz0123456789_-abcde';
const _json = {'content-type': 'application/json'};

Map<String, dynamic> _loginBody({bool mustChange = false}) => {
      'token': 'session-token',
      'expires_at': DateTime.now().toUtc().add(const Duration(hours: 12)).toIso8601String(),
      'must_change_password': mustChange,
      'professional': {'full_name': 'Dr. Sample (test)', 'profession': 'Psychologist'},
    };

Map<String, dynamic> _openBody() {
  Map<String, dynamic> score(String sev) =>
      {'score': 0, 'maximum_score': 42, 'severity': sev};
  Map<String, dynamic> guide(String sev) => {
        'severity': sev,
        'title': 't',
        'message': 'm',
        'recommendation': 'r',
      };
  return {
    'status': 'success',
    'assessment': {
      'depression': score('Normal'),
      'anxiety': score('Normal'),
      'stress': score('Normal'),
    },
    'guidance': {
      'depression': guide('Normal'),
      'anxiety': guide('Normal'),
      'stress': guide('Normal'),
    },
    'notice': 'n',
    'responses': List<int>.filled(42, 0),
    'shared_at': '2026-11-07T04:00:00+00:00',
    'expires_at': '2026-11-22T04:00:00+00:00',
  };
}

class _MemoryStore implements ProfessionalSessionStore {
  ProfessionalSession? value;

  @override
  Future<ProfessionalSession?> load() async => value;

  @override
  Future<void> save(ProfessionalSession session) async {
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  group('ShareQrPayload', () {
    test('accepts muni://share/<token>', () {
      expect(ShareQrPayload.parse('muni://share/$_token'), _token);
    });

    test('accepts a bare token (manual entry)', () {
      expect(ShareQrPayload.parse('  $_token  '), _token);
    });

    test('explains demo codes', () {
      expect(
        () => ShareQrPayload.parse('https://demo.invalid/share/$_token'),
        throwsA(isA<InvalidShareQr>()
            .having((e) => e.message, 'message', contains('demo'))),
      );
    });

    test('rejects other URLs and short codes', () {
      expect(() => ShareQrPayload.parse('https://example.com/$_token'),
          throwsA(isA<InvalidShareQr>()));
      expect(() => ShareQrPayload.parse('muni://share/short'),
          throwsA(isA<InvalidShareQr>()));
    });
  });

  group('ApiService professional endpoints', () {
    test('login parses session and password-change flag', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((_) async =>
            http.Response(jsonEncode(_loginBody(mustChange: true)), 200, headers: _json)),
      );
      final s = await api.professionalLogin(username: 'u', password: 'p');
      expect(s.token, 'session-token');
      expect(s.mustChangePassword, isTrue);
      expect(s.fullName, 'Dr. Sample (test)');
    });

    test('login 401 -> UnauthorizedException', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((_) async =>
            http.Response('{"detail":"no"}', 401, headers: _json)),
      );
      await expectLater(
        api.professionalLogin(username: 'u', password: 'p'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('openShare sends bearer token in header and token in body', () async {
      late http.Request captured;
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode(_openBody()), 200, headers: _json);
        }),
      );
      final view = await api.openShare('session-token', _token);

      expect(captured.headers['Authorization'], 'Bearer session-token');
      expect(captured.url.path, '/api/professional/shares/open/');
      expect(captured.url.toString(), isNot(contains(_token)));
      expect(jsonDecode(captured.body)['token'], _token);
      expect(view.responses.length, 42);
    });

    test('validation errors expose server messages', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'status': 'error',
                'errors': {'new_password': ['This password is too common.']},
              }),
              400,
              headers: _json,
            )),
      );
      await expectLater(
        api.changePassword('s', currentPassword: 'a', newPassword: 'b'),
        throwsA(isA<ValidationException>().having(
          (e) => e.displayMessage,
          'displayMessage',
          'This password is too common.',
        )),
      );
    });
  });

  test('controller signs out locally when the server says 401', () async {
    final store = _MemoryStore();
    final api = ApiService(
      baseUrl: 'http://test.local',
      client: MockClient((req) async {
        if (req.url.path == '/api/professional/login/') {
          return http.Response(jsonEncode(_loginBody()), 200, headers: _json);
        }
        return http.Response('{"detail":"expired"}', 401, headers: _json);
      }),
    );
    final controller = ProfessionalController(api: api, store: store);

    await controller.signIn('u', 'p');
    expect(controller.session, isNotNull);

    await expectLater(
      controller.openShare(_token),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(controller.session, isNull);
    expect(store.value, isNull);
  });
}