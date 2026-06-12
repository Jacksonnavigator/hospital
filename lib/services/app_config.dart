class AppConfig {
  /// Backend API base URL.
  ///
  /// Override with `--dart-define=BACKEND_BASE_URL=http://your-host:8000`
  /// when building or running the app if needed.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
