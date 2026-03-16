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

  static const String developmentBaseUrl = 'https://api.dev.goappdriver.com';
  static const String uatBaseUrl = 'https://api.uat.goappdriver.com';
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
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    switch (environment) {
      case AppEnvironment.production:
        return productionBaseUrl;
      case AppEnvironment.uat:
        return uatBaseUrl;
      case AppEnvironment.development:
        return developmentBaseUrl;
    }
  }

  static Uri resolve(String path) {
    return Uri.parse(baseUrl).resolve(path);
  }
}
