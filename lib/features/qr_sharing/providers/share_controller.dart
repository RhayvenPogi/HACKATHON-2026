import 'package:flutter/foundation.dart';
import 'package:muni_app/features/qr_sharing/data/share_repository.dart';
import 'package:muni_app/features/qr_sharing/data/share_storage.dart';
import 'package:muni_app/models/share_session.dart';

class ShareController extends ChangeNotifier {
  ShareController({
    required this._repository,
    required this._storage,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now;

  final ShareRepository _repository;
  final ShareStorage _storage;
  final DateTime Function() _clock;

  ShareSession? _active;
  bool _busy = false;

  bool get isDemo => _repository.isDemo;
  bool get isBusy => _busy;

  /// Null when there is no share, or it has expired.
  ShareSession? get activeShare {
    final session = _active;
    if (session == null || session.isExpiredAt(_clock())) return null;
    return session;
  }

  Future<void> load() async {
    try {
      final stored = await _storage.load();
      final bool stale = stored != null &&
          (stored.isExpiredAt(_clock()) || stored.isDemo != isDemo);
      if (stale) {
        await _storage.clear();
        _active = null;
      } else {
        _active = stored;
      }
    } catch (_) {
      _active = null; // Storage unavailable: behave as "no active share".
    }
    notifyListeners();
  }

  /// Revokes any existing share first, so only one QR works at a time.
  Future<ShareSession> createShare(List<int> responses) async {
    if (_busy) throw StateError('A sharing request is already in progress.');
    _setBusy(true);
    try {
      final previous = activeShare;
      if (previous != null) await _repository.revokeShare(previous);
      final session = await _repository.createShare(responses);
      await _storage.save(session);
      _active = session;
      return session;
    } finally {
      _setBusy(false);
    }
  }

  /// Local copy is cleared only after the server confirms, so a failed
  /// revoke can be retried.
  Future<void> revoke() async {
    final session = _active;
    if (session == null || _busy) return;
    _setBusy(true);
    try {
      await _repository.revokeShare(session);
      await _storage.clear();
      _active = null;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}