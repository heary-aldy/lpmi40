class AppConstants {
  // Timeout durations
  static const Duration standardTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 15);
  static const Duration quickTimeout = Duration(seconds: 5);

  // Cache durations
  static const Duration authCacheTimeout = Duration(minutes: 1);
  static const Duration dataCacheTimeout = Duration(minutes: 5);

  // Error messages
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  // App info
  static const String appName = 'LPMI40';
  static const String appVersion = '2.0.0';
  static const String appFullName = 'Lagu Pujian Masa Ini';
}
