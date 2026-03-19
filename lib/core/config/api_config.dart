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

  // Replace this with the live URL when the backend is online.
  static const String ngrokBaseUrl =
      'https://nia-unterrestrial-remy.ngrok-free.dev';

  static const String manualBaseUrl = 'http://localhost:3000';
  static const String developmentBaseUrl = ngrokBaseUrl;
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

    // In debug mode with mock API disabled, use manualBaseUrl if set.
    // Falls back to ngrokBaseUrl via developmentBaseUrl otherwise.
    final String manual = manualBaseUrl.trim();
    if (kDebugMode && !Env.mockApi && manual.isNotEmpty) {
      return _normalizeLoopback(manual);
    }

    switch (environment) {
      case AppEnvironment.production:
        return productionBaseUrl;
      case AppEnvironment.uat:
      case AppEnvironment.development:
        return developmentBaseUrl; // Points to ngrokBaseUrl
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
