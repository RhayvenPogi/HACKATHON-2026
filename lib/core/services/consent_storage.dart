import 'package:shared_preferences/shared_preferences.dart';

/// Stores ONLY which consent version the user accepted.
/// Never store assessment answers or results here.
class ConsentStorage {
  ConsentStorage(this._prefs);

  /// Bump this whenever consent wording changes to re-prompt all users.
  static const int currentConsentVersion = 1;
  static const String storageKey = 'consent_version_accepted';

  final SharedPreferences _prefs;

  static Future<ConsentStorage> create() async {
    return ConsentStorage(await SharedPreferences.getInstance());
  }

  bool get hasValidConsent =>
      _prefs.getInt(storageKey) == currentConsentVersion;

  Future<void> recordConsent() async {
    await _prefs.setInt(storageKey, currentConsentVersion);
  }

  Future<void> withdrawConsent() async {
    await _prefs.remove(storageKey);
  }
}