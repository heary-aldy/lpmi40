// lib/app/data/constants/api_constants.dart

/// A class to hold all API-related constants.
/// REASON: Centralizing constants prevents hardcoding URLs in multiple places,
/// making the app easier to maintain and update.
class ApiConstants {
  /// The base URL for the API.
  static const String baseUrl = 'https://lpmi.iainpalopo.ac.id/api';

  /// The endpoint for user login.
  static const String loginUrl = '$baseUrl/login';

  /// Add other endpoints here as your app grows.
  /// Example:
  /// static const String profileUrl = '$baseUrl/profile';
  /// static const String documentsUrl = '$baseUrl/documents';
}
