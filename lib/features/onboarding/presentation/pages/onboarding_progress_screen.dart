import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/document_verify/presentation/pages/verification_screen.dart';
import 'package:goapp/features/documents/presentation/model/document_upload_model.dart';
import 'package:goapp/features/documents/presentation/pages/document_upload_screen.dart';
import 'package:goapp/features/onboarding/data/models/onboarding_progress_response_model.dart';
import 'package:goapp/features/onboarding/presentation/cubit/onboarding_progress_cubit.dart';
import 'package:goapp/features/onboarding/presentation/cubit/onboarding_progress_state.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup_page.dart';

class OnboardingProgressScreen extends StatelessWidget {
  const OnboardingProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingProgressCubit()..load(),
      child: const _OnboardingProgressView(),
    );
  }
}

class _OnboardingProgressView extends StatefulWidget {
  const _OnboardingProgressView();

  @override
  State<_OnboardingProgressView> createState() => _OnboardingProgressViewState();
}

class _OnboardingProgressViewState extends State<_OnboardingProgressView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppAppBar(title: 'Onboarding'),
      body: BlocBuilder<OnboardingProgressCubit, OnboardingProgressState>(
        builder: (context, state) {
          return switch (state) {
            OnboardingProgressLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            OnboardingProgressFailure(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<OnboardingProgressCubit>().load(),
              ),
            OnboardingProgressSuccess(:final data) => _ProgressBody(
                completionPercentage: data.completionPercentage,
                steps: data.steps,
                overallStatus: data.overallStatus,
                onContinue: () => _continueToNext(context, data.steps),
              ),
          };
        },
      ),
    );
  }

  void _continueToNext(
    BuildContext context,
    List<OnboardingProgressStepModel> steps,
  ) {
    if (steps.isEmpty) return;
    final currentIndex = steps.indexWhere((s) => !s.isCompleted);
    final idx = currentIndex == -1 ? (steps.length - 1) : currentIndex;
    final step = steps[idx];
    final id = step.id.toLowerCase();

    Widget target;
    switch (id) {
      case 'profile':
        target = const ProfileSetupPage();
        break;
      case 'documents':
        target = const VerificationScreen();
        break;
      case 'bank':
        final bankIndex = DocumentUploadState.initial().steps.length;
        target = DocumentUploadScreen(initialStepIndex: bankIndex);
        break;
      default:
        target = const ProfileSetupPage();
        break;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.completionPercentage,
    required this.steps,
    required this.overallStatus,
    required this.onContinue,
  });

  final int completionPercentage;
  final List<OnboardingProgressStepModel> steps;
  final String? overallStatus;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexWhere((s) => !s.isCompleted);
    final activeIndex = currentIndex == -1 ? (steps.length - 1) : currentIndex;

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
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
  });

  final String title;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final border = completed
        ? AppColors.emerald
        : (active ? AppColors.hexFF0F4CB9 : AppColors.hexFFD5DDE5);
    final bg = completed
        ? AppColors.emerald.withValues(alpha: 0.06)
        : (active ? AppColors.hexFF0F4CB9.withValues(alpha: 0.05) : AppColors.white);

    return Container(
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            completed ? 'Completed' : (active ? 'Current' : 'Pending'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: completed
                  ? AppColors.emerald
                  : (active ? AppColors.hexFF0F4CB9 : AppColors.hexFF8FA0B0),
            ),
          ),
        ],
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

