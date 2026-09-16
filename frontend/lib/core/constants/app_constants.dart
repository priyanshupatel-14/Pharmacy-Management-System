class AppConstants {
  static const String appName = 'Pharmacy Management System';
  static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080/api');
  static const String tokenKey = 'auth_token';
}
