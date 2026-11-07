import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:muni_app/models/professional_session.dart';

abstract interface class ProfessionalSessionStore {
  Future<ProfessionalSession?> load();
  Future<void> save(ProfessionalSession session);
  Future<void> clear();
}

/// Encrypted on-device storage for the professional's session token only.
class SecureProfessionalSessionStore implements ProfessionalSessionStore {
  SecureProfessionalSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'professional_session';
  final FlutterSecureStorage _storage;

  @override
  Future<ProfessionalSession?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Corrupt session.');
      }
      return ProfessionalSession.fromJson(decoded);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(ProfessionalSession session) async {
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}