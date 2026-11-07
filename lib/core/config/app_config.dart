/// Runtime configuration for FLOW.
///
/// Override the API base URL at run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// Default assumes a physical phone over USB with:
///   adb reverse tcp:8000 tcp:8000
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}