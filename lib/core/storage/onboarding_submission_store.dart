import 'shared_preferences_store.dart';

class OnboardingSubmissionStore {
  OnboardingSubmissionStore._();

  static const String _submissionIdKey = 'onboarding.submission_id';
  static const String _submissionStatusKey = 'onboarding.submission_status';

  static String? submissionId() =>
      SharedPreferencesStore.global.getString(_submissionIdKey);

  static String? submissionStatus() =>
      SharedPreferencesStore.global.getString(_submissionStatusKey);

  static Future<void> save({
    required String submissionId,
    String? status,
  }) async {
    final String id = submissionId.trim();
    if (id.isEmpty) return;
    await SharedPreferencesStore.global.setString(_submissionIdKey, id);
    final String st = (status ?? '').trim();
    if (st.isNotEmpty) {
      await SharedPreferencesStore.global.setString(_submissionStatusKey, st);
    }
  }

  static Future<void> clear() async {
    await SharedPreferencesStore.global.remove(_submissionIdKey);
    await SharedPreferencesStore.global.remove(_submissionStatusKey);
  }
}
