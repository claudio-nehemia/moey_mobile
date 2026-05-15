import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://demo.moeygroup.com/api';
  static String get appName => dotenv.env['APP_NAME'] ?? 'MOEY Mobile';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get companyName => dotenv.env['COMPANY_NAME'] ?? 'PT. Moey Living Indonesia';
  static String get env => dotenv.env['ENV'] ?? 'staging';

  static bool get isDevelopment => env == 'development' || env == 'dev';
  static bool get isProduction => env == 'production' || env == 'prod';
}
