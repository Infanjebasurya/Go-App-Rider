class OnboardingProgressStepModel {
  const OnboardingProgressStepModel({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final bool isCompleted;

  factory OnboardingProgressStepModel.fromJson(Map<String, dynamic> json) {
    return OnboardingProgressStepModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      isCompleted:
          _parseBool(json['is_completed'] ?? json['isCompleted']) ?? false,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'success') return true;
      if (normalized == 'false' || normalized == 'failed') return false;
    }
    return null;
  }
}

class OnboardingProgressResponseModel {
  const OnboardingProgressResponseModel({
    required this.success,
    required this.completionPercentage,
    required this.steps,
    this.overallStatus,
  });

  final bool success;
  final String? overallStatus;
  final List<OnboardingProgressStepModel> steps;
  final int completionPercentage;

  factory OnboardingProgressResponseModel.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['steps'];
    final parsedSteps = (stepsRaw is List ? stepsRaw : const <dynamic>[])
        .whereType<Map>()
        .map(
          (e) => OnboardingProgressStepModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList(growable: false);

    final completionRaw =
        json['completion_percentage'] ?? json['completionPercentage'];
    final completion = completionRaw is num
        ? completionRaw.toInt()
        : int.tryParse(completionRaw?.toString() ?? '') ?? 0;

    return OnboardingProgressResponseModel(
      success:
          OnboardingProgressStepModel._parseBool(
            json['success'] ?? json['status'],
          ) ??
          false,
      overallStatus: (json['overall_status'] ?? json['overallStatus'])
          ?.toString(),
      steps: parsedSteps,
      completionPercentage: completion.clamp(0, 100),
    );
  }
}
