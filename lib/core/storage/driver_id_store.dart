import 'shared_preferences_store.dart';

class DriverIdStore {
  DriverIdStore._();

  static const String _driverIdKey = 'driver.driver_id';
  static const String _profileRequestIdKey = 'driver.profile_request_id';

  static String? driverId() =>
      SharedPreferencesStore.global.getString(_driverIdKey);

  static String? lastProfileRequestId() =>
      SharedPreferencesStore.global.getString(_profileRequestIdKey);

  static Future<void> saveDriverId(String driverId) async {
    final value = driverId.trim();
    if (value.isEmpty) return;
    await SharedPreferencesStore.global.setString(_driverIdKey, value);
  }

  static Future<void> saveLastProfileRequestId(String requestId) async {
    final value = requestId.trim();
    if (value.isEmpty) return;
    await SharedPreferencesStore.global.setString(_profileRequestIdKey, value);
  }

  static Future<void> clear() async {
    await SharedPreferencesStore.global.remove(_driverIdKey);
    await SharedPreferencesStore.global.remove(_profileRequestIdKey);
  }
}
