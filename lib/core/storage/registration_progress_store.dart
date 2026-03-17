import 'dart:convert';

import 'shared_preferences_store.dart';

enum RegistrationStep {
  none,
  profileSetup,
  citySelection,
  vehicleSelection,
  vehicleDetails,
  verification,
  documentUpload,
  verificationSubmitted,
  home,
}

class RegistrationProgress {
  final bool otpVerified;
  final bool onboardingSeen;
  final RegistrationStep step;
  final String? cityId;
  final String? vehicleType;
  final String? vehicleTypeId;
  final int? documentStepIndex;

  const RegistrationProgress({
    required this.otpVerified,
    required this.onboardingSeen,
    required this.step,
    this.cityId,
    this.vehicleType,
    this.vehicleTypeId,
    this.documentStepIndex,
  });

  factory RegistrationProgress.empty() => const RegistrationProgress(
    otpVerified: false,
    onboardingSeen: false,
    step: RegistrationStep.none,
  );

  bool get shouldResume => otpVerified && step != RegistrationStep.none;

  RegistrationProgress copyWith({
    bool? otpVerified,
    bool? onboardingSeen,
    RegistrationStep? step,
    String? cityId,
    String? vehicleType,
    String? vehicleTypeId,
    int? documentStepIndex,
    bool clearCity = false,
    bool clearVehicle = false,
    bool clearDocumentStep = false,
  }) {
    return RegistrationProgress(
      otpVerified: otpVerified ?? this.otpVerified,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      step: step ?? this.step,
      cityId: clearCity ? null : (cityId ?? this.cityId),
      vehicleType: clearVehicle ? null : (vehicleType ?? this.vehicleType),
      vehicleTypeId: clearVehicle
          ? null
          : (vehicleTypeId ?? this.vehicleTypeId),
      documentStepIndex: clearDocumentStep
          ? null
          : (documentStepIndex ?? this.documentStepIndex),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otpVerified': otpVerified,
      'onboardingSeen': onboardingSeen,
      'step': step.name,
      'cityId': cityId,
      'vehicleType': vehicleType,
      'vehicleTypeId': vehicleTypeId,
      'documentStepIndex': documentStepIndex,
    };
  }

  factory RegistrationProgress.fromJson(Map<String, dynamic> json) {
    final stepRaw = json['step'] as String?;
    final step = RegistrationStep.values.firstWhere(
      (e) => e.name == stepRaw,
      orElse: () => RegistrationStep.none,
    );
    final docIndex = json['documentStepIndex'];
    return RegistrationProgress(
      otpVerified: json['otpVerified'] == true,
      onboardingSeen: json['onboardingSeen'] == true,
      step: step,
      cityId: json['cityId'] as String?,
      vehicleType: json['vehicleType'] as String?,
      vehicleTypeId: (json['vehicleTypeId'] ?? json['vehicle_type_id'])
          ?.toString(),
      documentStepIndex: docIndex is int ? docIndex : null,
    );
  }
}

class RegistrationProgressStore {
  static const String _key = 'registration_progress_v1';

  static Future<RegistrationProgress> load() async {
    final prefs = SharedPreferencesStore.global;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return RegistrationProgress.empty();
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return RegistrationProgress.fromJson(map);
      }
    } catch (_) {}
    return RegistrationProgress.empty();
  }

  static Future<void> save(RegistrationProgress progress) async {
    final prefs = SharedPreferencesStore.global;
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  static Future<void> clear() async {
    final prefs = SharedPreferencesStore.global;
    await prefs.remove(_key);
  }

  static Future<void> markOtpVerified() async {
    final progress = await load();
    await save(progress.copyWith(otpVerified: true));
  }

  static Future<void> markOnboardingSeen() async {
    final progress = await load();
    await save(progress.copyWith(onboardingSeen: true));
  }

  static Future<void> setStep(
    RegistrationStep step, {
    String? cityId,
    String? vehicleType,
    String? vehicleTypeId,
    int? documentStepIndex,
    bool clearCity = false,
    bool clearVehicle = false,
    bool clearDocumentStep = false,
  }) async {
    final progress = await load();
    await save(
      progress.copyWith(
        step: step,
        cityId: cityId,
        vehicleType: vehicleType,
        vehicleTypeId: vehicleTypeId,
        documentStepIndex: documentStepIndex,
        clearCity: clearCity,
        clearVehicle: clearVehicle,
        clearDocumentStep: clearDocumentStep,
      ),
    );
  }

  static Future<void> resetForSignedOut({
    bool showLoginOnNextLaunch = true,
  }) async {
    final current = await load();
    await save(
      RegistrationProgress.empty().copyWith(
        onboardingSeen: showLoginOnNextLaunch ? true : current.onboardingSeen,
      ),
    );
  }
}
