import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/document_verify/presentation/pages/verification_screen.dart';
import 'package:goapp/features/documents/presentation/model/document_upload_model.dart';
import 'package:goapp/features/documents/presentation/pages/document_upload_screen.dart';
import 'package:goapp/features/home/presentation/pages/home_page.dart';
import 'package:goapp/features/onboarding/data/models/onboarding_progress_response_model.dart';
import 'package:goapp/features/onboarding/presentation/cubit/onboarding_progress_cubit.dart';
import 'package:goapp/features/onboarding/presentation/cubit/onboarding_progress_state.dart';
import 'package:goapp/features/onboarding/presentation/cubit/onboarding_submit_cubit.dart';
import 'package:goapp/features/onboarding/presentation/cubit/onboarding_submit_state.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup_page.dart';

class OnboardingProgressScreen extends StatelessWidget {
  const OnboardingProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => OnboardingProgressCubit()),
        BlocProvider(create: (_) => OnboardingSubmitCubit()),
      ],
      child: const _OnboardingProgressView(),
    );
  }
}

class _OnboardingProgressView extends StatefulWidget {
  const _OnboardingProgressView();

  @override
  State<_OnboardingProgressView> createState() =>
      _OnboardingProgressViewState();
}

class _OnboardingProgressViewState extends State<_OnboardingProgressView> {
  bool _didNavigateHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OnboardingProgressCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppAppBar(title: 'Onboarding'),
      body: MultiBlocListener(
        listeners: [
          BlocListener<OnboardingSubmitCubit, OnboardingSubmitState>(
            listenWhen: (prev, next) =>
                prev.errorMessage != next.errorMessage ||
                prev.submissionId != next.submissionId,
            listener: (context, state) {
              final String error = (state.errorMessage ?? '').trim();
              if (error.isNotEmpty) {
                SnackBarUtils.showError(context, error);
              }

              if (!_didNavigateHome && state.isSuccess) {
                _didNavigateHome = true;
                final String message = (state.message ?? '').trim().isNotEmpty
                    ? state.message!.trim()
                    : 'Application submitted successfully.';
                SnackBarUtils.show(context, message);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<OnboardingProgressCubit, OnboardingProgressState>(
          builder: (context, state) {
            if (state is OnboardingProgressLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OnboardingProgressFailure) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<OnboardingProgressCubit>().load(),
              );
            }
            if (state is OnboardingProgressSuccess) {
              final steps = _normalizeSteps(state.data.steps);
              final bool allDone =
                  steps.isNotEmpty && steps.every((s) => s.isCompleted);

              return BlocBuilder<OnboardingSubmitCubit, OnboardingSubmitState>(
                builder: (context, submitState) {
                  return _ProgressBody(
                    completionPercentage: state.data.completionPercentage,
                    steps: steps,
                    overallStatus: state.data.overallStatus,
                    declarationAccepted: submitState.declarationAccepted,
                    isSubmitting: submitState.isSubmitting,
                    onDeclarationChanged: (value) {
                      context
                          .read<OnboardingSubmitCubit>()
                          .setDeclarationAccepted(value);
                    },
                    onContinue: () => _continueToNext(context, steps),
                    onSubmit: () => context
                        .read<OnboardingSubmitCubit>()
                        .submit(allStepsCompleted: allDone),
                    onStepTap: (step) => _navigateToStep(context, step.id),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static List<OnboardingProgressStepModel> _normalizeSteps(
    List<OnboardingProgressStepModel> apiSteps,
  ) {
    const List<String> order = <String>['profile', 'documents', 'bank'];

    final Map<String, OnboardingProgressStepModel> byId =
        <String, OnboardingProgressStepModel>{
          for (final s in apiSteps) s.id.toLowerCase().trim(): s,
        };

    String titleFor(String id) {
      switch (id) {
        case 'profile':
          return 'Personal Details';
        case 'documents':
          return 'Document Upload';
        case 'bank':
          return 'Bank Details';
      }
      return id;
    }

    final List<OnboardingProgressStepModel> normalized =
        <OnboardingProgressStepModel>[
          for (final id in order)
            byId[id] ??
                OnboardingProgressStepModel(
                  id: id,
                  title: titleFor(id),
                  isCompleted: false,
                ),
        ];

    final Iterable<OnboardingProgressStepModel> extras = apiSteps.where((s) {
      final String key = s.id.toLowerCase().trim();
      return key.isNotEmpty && !order.contains(key);
    });

    normalized.addAll(extras);
    return normalized;
  }

  void _continueToNext(
    BuildContext context,
    List<OnboardingProgressStepModel> steps,
  ) {
    if (steps.isEmpty) return;

    final bool allDone = steps.every((s) => s.isCompleted);
    if (allDone) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    final int currentIndex = steps.indexWhere((s) => !s.isCompleted);
    final int idx = currentIndex == -1 ? 0 : currentIndex;
    _navigateToStep(context, steps[idx].id);
  }

  void _navigateToStep(BuildContext context, String stepId) {
    final String id = stepId.toLowerCase().trim();

    Widget target;
    switch (id) {
      case 'profile':
        target = const ProfileSetupPage();
        break;
      case 'documents':
        target = const VerificationScreen();
        break;
      case 'bank':
        final int bankIndex = DocumentUploadState.initial().steps.length;
        target = DocumentUploadScreen(initialStepIndex: bankIndex);
        break;
      default:
        SnackBarUtils.showError(context, 'Unknown step: $stepId');
        return;
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => target));
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.completionPercentage,
    required this.steps,
    required this.overallStatus,
    required this.declarationAccepted,
    required this.isSubmitting,
    required this.onDeclarationChanged,
    required this.onContinue,
    required this.onSubmit,
    required this.onStepTap,
  });

  final int completionPercentage;
  final List<OnboardingProgressStepModel> steps;
  final String? overallStatus;
  final bool declarationAccepted;
  final bool isSubmitting;
  final ValueChanged<bool> onDeclarationChanged;
  final VoidCallback onContinue;
  final VoidCallback onSubmit;
  final ValueChanged<OnboardingProgressStepModel> onStepTap;

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexWhere((s) => !s.isCompleted);
    final activeIndex = currentIndex == -1 ? (steps.length - 1) : currentIndex;
    final bool allDone = steps.isNotEmpty && steps.every((s) => s.isCompleted);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Onboarding Progress',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                if (overallStatus != null && overallStatus!.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceF5,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      overallStatus!.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.hexFF6B7C93,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$completionPercentage% completed',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.hexFF6B7C93,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionPercentage.clamp(0, 100) / 100,
                minHeight: 6,
                backgroundColor: AppColors.hexFFE8EDF2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.emerald,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: steps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final step = steps[i];
                  final completed = step.isCompleted;
                  final active = i == activeIndex;
                  return _StepTile(
                    title: step.title,
                    completed: completed,
                    active: active,
                    onTap: () => onStepTap(step),
                  );
                },
              ),
            ),
            if (allDone) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceF5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: declarationAccepted,
                      onChanged: isSubmitting
                          ? null
                          : (value) => onDeclarationChanged(value ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'I confirm that the information and documents provided are accurate.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hexFF2C3A4A,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: allDone
                    ? ((declarationAccepted && !isSubmitting) ? onSubmit : null)
                    : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: allDone
                    ? (isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Submitting...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Submit Application',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ))
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.title,
    required this.completed,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool completed;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = completed
        ? AppColors.emerald
        : (active ? AppColors.hexFF0F4CB9 : AppColors.hexFFD5DDE5);
    final bg = completed
        ? AppColors.emerald.withValues(alpha: 0.06)
        : (active
              ? AppColors.hexFF0F4CB9.withValues(alpha: 0.05)
              : AppColors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              _StepIcon(completed: completed, active: active),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                completed ? 'Completed' : (active ? 'Current' : 'Pending'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: completed
                      ? AppColors.emerald
                      : (active
                            ? AppColors.hexFF0F4CB9
                            : AppColors.hexFF8FA0B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.completed, required this.active});

  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return const Icon(Icons.check_circle, color: AppColors.emerald);
    }
    return Icon(
      active ? Icons.radio_button_checked : Icons.radio_button_off,
      color: active ? AppColors.hexFF0F4CB9 : AppColors.hexFF8FA0B0,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
