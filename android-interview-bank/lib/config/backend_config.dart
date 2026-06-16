class BackendConfig {
  static const baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://54.150.9.209/interview',
  );

  static const timeout = Duration(seconds: 3);
}
