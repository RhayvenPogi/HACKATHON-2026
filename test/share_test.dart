import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/features/qr_sharing/data/share_repository.dart';
import 'package:muni_app/features/qr_sharing/data/share_storage.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';
import 'package:muni_app/models/assessment_request.dart';
import 'package:muni_app/models/share_session.dart';

final DateTime _now = DateTime.utc(2026, 11, 7, 12);
List<int> _responses() => List<int>.filled(21, 1);

ShareSession _session(String token, {Duration validFor = const Duration(days: 15), bool demo = false}) =>
    ShareSession(
      token: token,
      shareUrl: 'https://example.test/s/$token/',
      expiresAt: _now.add(validFor),
      isDemo: demo,
    );

class _MemoryStorage implements ShareStorage {
  ShareSession? value;

  @override
  Future<ShareSession?> load() async => value;

  @override
  Future<void> save(ShareSession session) async {
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class _FakeRepo implements ShareRepository {
  @override
  bool get isDemo => false;

  int created = 0;
  final List<String> revoked = [];

  @override
  Future<ShareSession> createShare(List<int> responses) async {
    created++;
    return _session('token-$created', demo: isDemo);
  }

  @override
  Future<void> revokeShare(ShareSession session) async {
    revoked.add(session.token);
  }
}

void main() {
  group('ShareSession', () {
    test('survives a JSON round trip', () {
      final original = _session('abc', demo: true);
      final copy = ShareSession.fromJson(original.toJson());
      expect(copy.token, 'abc');
      expect(copy.shareUrl, original.shareUrl);
      expect(copy.isDemo, isTrue);
      expect(copy.expiresAt.isAtSameMomentAs(original.expiresAt), isTrue);
    });

    test('expires exactly at expiresAt', () {
      final s = _session('abc');
      expect(s.isExpiredAt(s.expiresAt.subtract(const Duration(seconds: 1))), isFalse);
      expect(s.isExpiredAt(s.expiresAt), isTrue);
    });
  });

  group('DemoShareRepository', () {
    test('creates an opaque token on an unresolvable domain, 15-day expiry',
        () async {
      final repo = DemoShareRepository(clock: () => _now);
      final s = await repo.createShare(_responses());

      expect(s.isDemo, isTrue);
      expect(s.token.length, greaterThanOrEqualTo(43));
      expect(Uri.parse(s.shareUrl).host, 'demo.invalid');
      expect(s.shareUrl, endsWith(s.token));
      expect(s.expiresAt, _now.add(const Duration(days: 15)));
    });

    test('rejects malformed responses', () async {
      await expectLater(
        DemoShareRepository().createShare(List<int>.filled(20, 0)),
        throwsArgumentError,
      );
    });
  });

  group('ShareController', () {
    late _FakeRepo repo;
    late _MemoryStorage storage;
    late ShareController controller;

    setUp(() {
      repo = _FakeRepo();
      storage = _MemoryStorage();
      controller = ShareController(
        repository: repo,
        storage: storage,
        clock: () => _now,
      );
    });

    test('createShare stores and exposes the session', () async {
      await controller.createShare(_responses());
      expect(controller.activeShare?.token, 'token-1');
      expect(storage.value?.token, 'token-1');
    });

    test('a new share revokes the previous one', () async {
      await controller.createShare(_responses());
      await controller.createShare(_responses());
      expect(repo.revoked, ['token-1']);
      expect(controller.activeShare?.token, 'token-2');
    });

    test('revoke clears both server and device', () async {
      await controller.createShare(_responses());
      await controller.revoke();
      expect(repo.revoked, ['token-1']);
      expect(controller.activeShare, isNull);
      expect(storage.value, isNull);
    });

    test('load discards expired and wrong-mode sessions', () async {
      storage.value = _session('old', validFor: const Duration(days: -1));
      await controller.load();
      expect(controller.activeShare, isNull);
      expect(storage.value, isNull);

      storage.value = _session('demo', demo: true);
      await controller.load();
      expect(controller.activeShare, isNull);
      expect(storage.value, isNull);
    });
  });

  group('ApiService share endpoints', () {
    test('createShare posts answers with consent and parses the session',
        () async {
      late http.Request captured;
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'token': 'abc',
              'share_url': 'https://server.test/s/abc/',
              'expires_at': '2026-11-22T12:00:00Z',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final s = await api.createShare(
        AssessmentRequest(_responses()),
        consentVersion: 1,
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(captured.url.path, '/api/shares/');
      expect(body['consent_given'], isTrue);
      expect(body['consent_version'], 1);
      expect((body['responses'] as List).length, 21);
      expect(s.token, 'abc');
      expect(s.isDemo, isFalse);
    });

    test('revokeShare treats 404 as already gone', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((_) async => http.Response(
              '{"detail":"Not found."}',
              404,
              headers: {'content-type': 'application/json'},
            )),
      );
      await api.revokeShare('abc');
    });

    test('revokeShare surfaces other server errors', () async {
      final api = ApiService(
        baseUrl: 'http://test.local',
        client: MockClient((_) async => http.Response('', 500)),
      );
      await expectLater(
        api.revokeShare('abc'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}