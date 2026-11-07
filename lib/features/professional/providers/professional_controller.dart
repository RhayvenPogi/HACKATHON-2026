import 'package:flutter/foundation.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/features/professional/data/professional_session_store.dart';
import 'package:muni_app/models/professional_session.dart';
import 'package:muni_app/models/shared_assessment_view.dart';

class ProfessionalController extends ChangeNotifier {
  ProfessionalController({
    required this._api,
    required this._store,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now;

  final ApiService _api;
  final ProfessionalSessionStore _store;
  final DateTime Function() _clock;

  ProfessionalSession? _session;
  bool _busy = false;

  bool get isBusy => _busy;

  /// Null when signed out or expired.
  ProfessionalSession? get session {
    final s = _session;
    if (s == null || s.isExpiredAt(_clock())) return null;
    return s;
  }

  Future<void> load() async {
    try {
      final stored = await _store.load();
      if (stored != null && stored.isExpiredAt(_clock())) {
        await _store.clear();
        _session = null;
      } else {
        _session = stored;
      }
    } catch (_) {
      _session = null;
    }
    notifyListeners();
  }

  Future<void> signIn(String username, String password) => _run(() async {
        final s = await _api.professionalLogin(
          username: username.trim(),
          password: password,
        );
        await _store.save(s);
        _session = s;
      });

  Future<void> changePassword(String current, String next) => _run(() async {
        final s = _requireSession();
        await _api.changePassword(
          s.token,
          currentPassword: current,
          newPassword: next,
        );
        final updated = s.copyWith(mustChangePassword: false);
        await _store.save(updated);
        _session = updated;
      });

  /// Never stores the result. Caller holds it only while displayed.
  Future<SharedAssessmentView> openShare(String shareToken) async {
    final s = _requireSession();
    try {
      return await _api.openShare(s.token, shareToken);
    } on UnauthorizedException {
      await _endLocalSession();
      rethrow;
    }
  }

  Future<void> signOut() async {
    final s = _session;
    await _endLocalSession();
    if (s != null) {
      try {
        await _api.professionalLogout(s.token);
      } on ApiException {
        // Local session is already gone; server session expires on its own.
      }
    }
  }

  ProfessionalSession _requireSession() =>
      session ?? (throw const UnauthorizedException());

  Future<void> _endLocalSession() async {
    _session = null;
    try {
      await _store.clear();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await action();
    } on UnauthorizedException {
      if (_session != null) await _endLocalSession();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}