import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/storage/text_field_store.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/documents/presentation/cubit/document_upload_cubit.dart';
import 'package:goapp/features/documents/presentation/model/document_upload_model.dart';
import 'package:goapp/features/documents/presentation/pages/document_upload_sections.dart';

class DrivingLicenseUploadScreen extends StatelessWidget {
  const DrivingLicenseUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DocumentUploadCubit>(param1: 1),
      child: const _DrivingLicenseUploadView(),
    );
  }
}

class _DrivingLicenseUploadView extends StatefulWidget {
  const _DrivingLicenseUploadView();

  @override
  State<_DrivingLicenseUploadView> createState() =>
      _DrivingLicenseUploadViewState();
}

class _DrivingLicenseUploadViewState extends State<_DrivingLicenseUploadView> {
  late final TextEditingController _numberController;
  bool _didPop = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentUploadCubit, DocumentUploadState>(
      listener: (context, state) {
        if (state.statusMessage == null ||
            state.statusMessage!.trim().isEmpty) {
          return;
        }

        if (!state.statusIsError) {
          final bool showSuccess = _shouldShowSuccessSnackbar(state);
          if (showSuccess) {
            SnackBarUtils.show(context, state.statusMessage!);
          }
        }

        if (state.statusIsError) {
          SnackBarUtils.showError(context, state.statusMessage!);
          context.read<DocumentUploadCubit>().clearStatusMessage();
          return;
        }

        if (!state.isSubmitting && !_didPop) {
          _didPop = true;
          context.read<DocumentUploadCubit>().clearStatusMessage();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pop(true);
          });
        }
      },
      listenWhen: (prev, next) =>
          prev.statusMessage != next.statusMessage ||
          prev.isSubmitting != next.isSubmitting,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppAppBar(
            title: 'Driving License',
            onBack: () => Navigator.of(context).pop(),
          ),
          body: Column(
            children: [
              Expanded(
                child: DocumentStepContent(
                  key: const ValueKey('driving_license_step'),
                  config: state.currentConfig,
                  stepData: state.currentDocStep,
                  numberController: _numberController,
                ),
              ),
              _BottomCta(
                label: 'Save',
                onTap: state.isSubmitting
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        await context
                            .read<DocumentUploadCubit>()
                            .saveAndUploadOnly();
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowSuccessSnackbar(DocumentUploadState state) {
    final String key = 'snackbar_once.${DocumentStep.drivingLicense.name}';
    final String signature =
        'front:${state.currentDocStep.frontPath ?? ''}|back:${state.currentDocStep.backPath ?? ''}|num:${state.currentDocStep.documentNumber.trim()}';

    final String? previous = TextFieldStore.read(key);
    if (previous == signature) return false;
    unawaited(TextFieldStore.write(key, signature));
    return true;
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafePadding = mediaQuery.padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        bottomInset + bottomSafePadding + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.coolwhite)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}
