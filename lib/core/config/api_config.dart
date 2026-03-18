import 'package:flutter/foundation.dart';

import '../utils/env.dart';

enum AppEnvironment { development, uat, production }

class ApiConfig {
  ApiConfig._();

  static const String _environmentValue = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Local dev base URL (only used in debug when MOCK_API=false).
  // Override via `--dart-define API_BASE_URL=...` when needed.
  static const String manualBaseUrl = 'http://localhost:3000';
  static const String developmentBaseUrl = 'https://api.dev.goappdriver.com';
  //static const String uatBaseUrl = 'https://api.uat.goappdriver.com';
  static const String productionBaseUrl = 'https://api.goappdriver.com';

  static AppEnvironment get environment {
    switch (_environmentValue.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.production;
      case 'stage':
      case 'uat':
        return AppEnvironment.uat;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.development;
    }
  }

  static String get baseUrl {
    final String override = _baseUrlOverride.trim();
    if (override.isNotEmpty) {
      return _normalizeLoopback(override);
    }

    // Avoid forcing localhost when running in mock mode (enabled by default).
    final String manual = manualBaseUrl.trim();
    if (kDebugMode && !Env.mockApi && manual.isNotEmpty) {
      return _normalizeLoopback(manual);
    }

    switch (environment) {
      case AppEnvironment.production:
        return productionBaseUrl;
      case AppEnvironment.uat:
      //  return uatBaseUrl;
      case AppEnvironment.development:
        return developmentBaseUrl;
    }
  }

  static Uri resolve(String path) {
    return Uri.parse(baseUrl).resolve(path);
  }

  /// On Android emulators, `localhost` points to the emulator/device itself.
  /// Map it to the host machine using the standard alias `10.0.2.2`.
  static String _normalizeLoopback(String url) {
    if (kIsWeb) return url;

    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) return url;

    final String host = parsed.host.trim().toLowerCase();
    final bool isLoopback =
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1';

    if (!isLoopback) return url;
    if (defaultTargetPlatform != TargetPlatform.android) return url;

    return parsed.replace(host: '10.0.2.2').toString();
  }
}
