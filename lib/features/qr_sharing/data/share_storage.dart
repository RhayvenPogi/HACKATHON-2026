import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:muni_app/models/share_session.dart';

abstract interface class ShareStorage {
  Future<ShareSession?> load();
  Future<void> save(ShareSession session);
  Future<void> clear();
}

/// Encrypted on-device storage (Android Keystore).
/// Holds ONLY the token, link and expiry, never scores or answers.
class SecureShareStorage implements ShareStorage {
  SecureShareStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'active_share_session';
  final FlutterSecureStorage _storage;

  @override
  Future<ShareSession?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Corrupt share session.');
      }
      return ShareSession.fromJson(decoded);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(ShareSession session) async {
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}