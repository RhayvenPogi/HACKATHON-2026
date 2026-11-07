/// Runtime configuration.
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///   flutter run --dart-define=SHARE_API_ENABLED=true   (once backend ships)
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  /// QR-sharing backend endpoints are NOT implemented yet.
  /// false = demo mode: QR codes are clearly labeled and unusable.
  static const bool shareApiEnabled = bool.fromEnvironment(
    'SHARE_API_ENABLED',
    defaultValue: true,
  );

  static const Duration shareValidity = Duration(days: 15);
}