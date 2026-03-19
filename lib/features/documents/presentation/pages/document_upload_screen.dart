import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/storage/text_field_store.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/appbar.dart';
import 'package:goapp/features/documents/presentation/pages/verification_submitted_screen.dart';
import 'package:goapp/core/di/injection.dart';

import '../cubit/document_upload_cubit.dart';
import '../model/document_upload_model.dart';
import 'document_camera_section.dart';
import 'document_preview_section.dart';
import 'document_upload_form.dart';
import 'document_upload_sections.dart';

class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key, this.initialStepIndex = 0});

  final int initialStepIndex;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DocumentUploadCubit>(param1: initialStepIndex),
      child: const _DocumentUploadView(),
    );
  }
}

class _DocumentUploadView extends StatefulWidget {
  const _DocumentUploadView();

  @override
  State<_DocumentUploadView> createState() => _DocumentUploadViewState();
}

class _DocumentUploadViewState extends State<_DocumentUploadView>
    with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _docControllers;
  bool _navigatedToSuccess = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _docControllers = List.generate(
      kStepConfigs.length,
      (_) => TextEditingController(),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _buildSlideAnimation(forward: true);
    _slideCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    for (final c in _docControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentUploadCubit, DocumentUploadState>(
      listener: (context, state) {
        final message = state.statusMessage;
        if (message != null && message.trim().isNotEmpty) {
          final bool isSuccess = !state.statusIsError;
          final DocumentStep messageStep = isSuccess
              ? _successMessageStep(state)
              : _errorMessageStep(state);

          final bool canSuppress =
              isSuccess &&
              (messageStep == DocumentStep.profilePhoto ||
                  messageStep == DocumentStep.drivingLicense ||
                  messageStep == DocumentStep.vehicleRC);

          final bool shouldShow = state.statusIsError
              ? true
              : (canSuppress
                    ? _shouldShowSuccessSnackbar(messageStep, state)
                    : true);

          if (shouldShow) {
            if (state.statusIsError) {
              SnackBarUtils.showError(context, message);
            } else {
              SnackBarUtils.show(context, message);
            }
          }
          context.read<DocumentUploadCubit>().clearStatusMessage();
        }
        if (state.isAllDone && !_navigatedToSuccess) {
          _navigatedToSuccess = true;
          _navigateToSuccess(context);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBack(context);
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppAppBar(
              title: 'GoApp',
              onBack: () => _handleBack(context),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: DocumentStepLabel(
                      currentStep: state.currentStepIndex,
                      totalSteps: state.totalSteps,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DocumentSegmentedBar(
                      currentStep: state.currentStepIndex,
                      totalSteps: state.totalSteps,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SlideTransition(
                      position: _slideIn,
                      child: state.isCurrentStepBank
                          ? BankAccountForm(
                              key: const ValueKey('bank_step'),
                              bankData: state.bankData,
                            )
                          : state.isCurrentStepProfile
                          ? ProfilePhotoStepContent(
                              key: const ValueKey('profile_photo_step'),
                              stepData: state.currentDocStep,
                              isProcessing: state.isProfileImageProcessing,
                              onCameraTap: () =>
                                  showProfileImageSourceSheet(context),
                            )
                          : DocumentStepContent(
                              key: ValueKey(state.currentStepIndex),
                              config: state.currentConfig,
                              stepData: state.currentDocStep,
                              numberController:
                                  _docControllers[state.currentStepIndex],
                            ),
                    ),
                  ),
                  DocumentActionButton(
                    isLastStep: state.isLastStep,
                    isCurrentStepBank: state.isCurrentStepBank,
                    isSubmitting: state.isSubmitting,
                    onTap: () {
                      _animateTransition(forward: true);
                      context.read<DocumentUploadCubit>().saveAndNext();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _buildSlideAnimation({required bool forward}) {
    _slideIn = Tween<Offset>(
      begin: Offset(forward ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  void _animateTransition({required bool forward}) {
    _buildSlideAnimation(forward: forward);
    _slideCtrl.forward(from: 0);
  }

  void _navigateToSuccess(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VerificationSubmittedScreen()),
    );
  }

  void _handleBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const VerificationSubmittedScreen()),
    );
  }

  DocumentStep _successMessageStep(DocumentUploadState state) {
    final int idx = state.currentStepIndex - 1;
    if (idx >= 0 && idx < state.steps.length) {
      return state.steps[idx].step;
    }
    return state.steps.isNotEmpty
        ? state.steps.last.step
        : DocumentStep.profilePhoto;
  }

  DocumentStep _errorMessageStep(DocumentUploadState state) {
    if (state.isCurrentStepBank) {
      return state.steps.isNotEmpty
          ? state.steps.last.step
          : DocumentStep.profilePhoto;
    }
    return state.currentDocStep.step;
  }

  StepData? _stepDataFor(DocumentUploadState state, DocumentStep step) {
    for (final s in state.steps) {
      if (s.step == step) return s;
    }
    return null;
  }

  bool _shouldShowSuccessSnackbar(
    DocumentStep step,
    DocumentUploadState state,
  ) {
    final StepData? stepData = _stepDataFor(state, step);
    if (stepData == null) return true;

    final String key = 'snackbar_once.${step.name}';

    final String signature = switch (step) {
      DocumentStep.profilePhoto => 'front:${stepData.frontPath ?? ''}',
      DocumentStep.drivingLicense || DocumentStep.vehicleRC =>
        'front:${stepData.frontPath ?? ''}|back:${stepData.backPath ?? ''}|num:${stepData.documentNumber.trim()}',
      _ => '',
    };

    if (signature.isEmpty) return true;
    final String? previous = TextFieldStore.read(key);
    if (previous == signature) return false;
    unawaited(TextFieldStore.write(key, signature));
    return true;
  }
}
