import 'dart:convert';
import 'dart:math';

import 'package:muni_app/core/config/app_config.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/models/assessment_request.dart';
import 'package:muni_app/models/share_session.dart';

/// Bump when the sharing consent wording changes.
const int shareConsentVersion = 1;

abstract interface class ShareRepository {
  bool get isDemo;
  Future<ShareSession> createShare(List<int> responses);
  Future<void> revokeShare(ShareSession session);
}

/// DEMO MODE: makes no network call. The QR link uses the reserved
/// `.invalid` domain, so it can never resolve or expose anything.
class DemoShareRepository implements ShareRepository {
  DemoShareRepository({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  bool get isDemo => true;

  @override
  Future<ShareSession> createShare(List<int> responses) async {
    AssessmentRequest(responses); // Validates shape only; data is discarded.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final token = _randomToken();
    return ShareSession(
      token: token,
      shareUrl: 'https://demo.invalid/share/$token',
      expiresAt: _clock().add(AppConfig.shareValidity),
      isDemo: true,
    );
  }

  @override
  Future<void> revokeShare(ShareSession session) async {}

  static String _randomToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

/// Real backend. Only used with --dart-define=SHARE_API_ENABLED=true.
class ApiShareRepository implements ShareRepository {
  ApiShareRepository(this._api);

  final ApiService _api;

  @override
  bool get isDemo => false;

  @override
  Future<ShareSession> createShare(List<int> responses) {
    return _api.createShare(
      AssessmentRequest(responses),
      consentVersion: shareConsentVersion,
    );
  }

  @override
  Future<void> revokeShare(ShareSession session) =>
      _api.revokeShare(session.token);
}