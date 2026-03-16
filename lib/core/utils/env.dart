class Env {
  const Env._();

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static const bool mockApi = bool.fromEnvironment(
    'MOCK_API',
    defaultValue: true,
  );

  static const bool newUser = bool.fromEnvironment(
    'NEW_USER',
    defaultValue: false,
  );

  static const bool resumeRideFromSavedStage = bool.fromEnvironment(
    'RESUME_RIDE_FROM_SAVED_STAGE',
    defaultValue: false,
  );

  static const bool enableDevicePreview = bool.fromEnvironment(
    'ENABLE_DEVICE_PREVIEW',
    defaultValue: false,
  );

  // B-07 FIX: Keys supplied via --dart-define at build time only.
  // No default value so a missing key fails fast rather than leaking a
  // committed key into the binary.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );

  static const String googleGeocodingApiKey = String.fromEnvironment(
    'GOOGLE_GEOCODING_API_KEY',
  );
}
