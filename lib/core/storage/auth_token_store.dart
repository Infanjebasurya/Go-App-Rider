import 'shared_preferences_store.dart';

class AuthTokenStore {
  AuthTokenStore._();

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _tokenTypeKey = 'auth.token_type';

  static Future<void> save({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
  }) async {
    final prefs = SharedPreferencesStore.global;
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    if (tokenType != null && tokenType.isNotEmpty) {
      await prefs.setString(_tokenTypeKey, tokenType);
    }
  }

  static String? accessToken() {
    return SharedPreferencesStore.global.getString(_accessTokenKey);
  }

  static String? refreshToken() {
    return SharedPreferencesStore.global.getString(_refreshTokenKey);
  }

  static String? tokenType() {
    return SharedPreferencesStore.global.getString(_tokenTypeKey);
  }

  static Future<void> clear() async {
    final prefs = SharedPreferencesStore.global;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenTypeKey);
  }
}
