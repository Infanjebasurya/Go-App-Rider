import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/documents/presentation/widgets/doc_number_field.dart';
import 'package:goapp/features/documents/presentation/widgets/document_capture_card.dart';

import '../cubit/document_upload_cubit.dart';
import '../model/document_upload_model.dart';
import 'document_camera_section.dart';
import 'package:goapp/core/widgets/shadow_button.dart';

class DocumentStepLabel extends StatelessWidget {
  const DocumentStepLabel({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Step ${currentStep + 1} to $totalSteps',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.emerald,
        letterSpacing: 0.3,
      ),
    );
  }
}

class DocumentSegmentedBar extends StatelessWidget {
  const DocumentSegmentedBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: active ? AppColors.emerald : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class DocumentStepContent extends StatelessWidget {
  const DocumentStepContent({
    super.key,
    required this.config,
    required this.stepData,
    required this.numberController,
  });

  final StepConfig config;
  final StepData stepData;
  final TextEditingController numberController;

  @override
  Widget build(BuildContext context) {
    final isCardCaptureStep =
        config.step == DocumentStep.drivingLicense ||
        config.step == DocumentStep.vehicleRC ||
        config.step == DocumentStep.identityAadhaar ||
        config.step == DocumentStep.identityPan;
    final requiresBackSide = config.requiresBackSide;
    final isAadhaarStep = config.step == DocumentStep.identityAadhaar;
    final isPanStep = config.step == DocumentStep.identityPan;
    final isVehicleStep = config.step == DocumentStep.vehicleRC;
    final isDrivingStep = config.step == DocumentStep.drivingLicense;
    final displayDocNumber = isAadhaarStep
        ? _formatAadhaarNumber(stepData.documentNumber)
        : stepData.documentNumber;

    if (numberController.text != displayDocNumber) {
      numberController.text = displayDocNumber;
      numberController.selection = TextSelection.collapsed(
        offset: numberController.text.length,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.headingNavy,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            config.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          DocumentCaptureCard(
            key: ValueKey('front_${config.step.name}'),
            label: config.frontLabel,
            captured: stepData.frontCaptured,
            onTap: () => showDocumentImageSourceSheet(
              context,
              onPick: (source) => context
                  .read<DocumentUploadCubit>()
                  .captureFront(source: source),
              onPickDocument: () =>
                  context.read<DocumentUploadCubit>().captureFrontDocument(),
              allowDocument: true,
            ),
            onRemove: () => context.read<DocumentUploadCubit>().removeFront(),
            filePath: stepData.frontPath,
            uploadType: stepData.frontType,
            showCardGuide: isCardCaptureStep,
          ),
          if (stepData.imageError != null && !stepData.frontCaptured) ...[
            const SizedBox(height: 10),
            _ImageErrorText(stepData.imageError!),
          ],
          if (requiresBackSide) ...[
            const SizedBox(height: 14),
            DocumentCaptureCard(
              key: ValueKey('back_${config.step.name}'),
              label: config.backLabel,
              captured: stepData.backCaptured,
              onTap: () => showDocumentImageSourceSheet(
                context,
                onPick: (source) => context
                    .read<DocumentUploadCubit>()
                    .captureBack(source: source),
                onPickDocument: () =>
                    context.read<DocumentUploadCubit>().captureBackDocument(),
                allowDocument: true,
              ),
              onRemove: () => context.read<DocumentUploadCubit>().removeBack(),
              filePath: stepData.backPath,
              uploadType: stepData.backType,
              showCardGuide: isCardCaptureStep,
            ),
            if (stepData.imageError != null && !stepData.backCaptured) ...[
              const SizedBox(height: 10),
              _ImageErrorText(stepData.imageError!),
            ],
          ],
          const SizedBox(height: 28),
          DocNumberField(
            key: ValueKey('number_${config.step.name}'),
            label: config.numberLabel,
            hint: config.numberHint,
            example: config.numberExample.isNotEmpty
                ? config.numberExample
                : null,
            controller: numberController,
            errorText: stepData.numberError,
            allowedPattern: config.allowedPattern,
            forceUppercase: config.forceUppercase,
            maxLength: config.maxLength,
            formatAsAadhaar: isAadhaarStep,
            formatAsPan: isPanStep,
            formatAsVehicleNumber: isVehicleStep,
            formatAsDrivingLicense: isDrivingStep,
            onChanged: (v) =>
                context.read<DocumentUploadCubit>().updateDocumentNumber(v),
          ),
          if (config.requiresExpiryDate) ...[
            const SizedBox(height: 16),
            _ExpiryDateField(
              label: config.expiryLabel,
              hint: config.expiryHint,
              value: stepData.expiryDate,
              errorText: stepData.expiryDateError,
              onPick: (picked) =>
                  context.read<DocumentUploadCubit>().updateExpiryDate(picked),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _formatAadhaarNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final capped = digits.length > 12 ? digits.substring(0, 12) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      buffer.write(capped[i]);
      if ((i + 1) % 4 == 0 && i + 1 != capped.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}

class _ExpiryDateField extends StatelessWidget {
  const _ExpiryDateField({
    required this.label,
    required this.hint,
    required this.value,
    required this.errorText,
    required this.onPick,
  });

  final String label;
  final String hint;
  final String value;
  final String? errorText;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final String display = value.trim().isEmpty ? hint : value.trim();
    final bool showHint = value.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.headingNavy,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime initial = DateTime.tryParse(value) ?? now;
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initial.isBefore(now) ? now : initial,
              firstDate: DateTime(now.year - 1, 1, 1),
              lastDate: DateTime(2100, 12, 31),
            );
            if (picked == null) return;
            onPick(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFE53935)
                    : const Color(0xFFE2E8F0),
              ),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: showHint ? Colors.grey : AppColors.headingNavy,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE53935)),
          ),
        ],
      ],
    );
  }
}

class _ImageErrorText extends StatelessWidget {
  const _ImageErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, color: Color(0xFFE53935)),
    );
  }
}

class DocumentActionButton extends StatelessWidget {
  const DocumentActionButton({
    super.key,
    required this.isLastStep,
    required this.isCurrentStepBank,
    required this.isSubmitting,
    required this.onTap,
  });

  final bool isLastStep;
  final bool isCurrentStepBank;
  final bool isSubmitting;
  final VoidCallback onTap;

  String get _label {
    if (isCurrentStepBank) return 'Save & Verify';
    if (isLastStep) return 'Submit All Documents';
    return 'Save & Next';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomSafePadding = mediaQuery.padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        bottomInset + bottomSafePadding + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.coolwhite)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ShadowButton(
          key: const Key('save_next_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: isSubmitting ? null : onTap,
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _label,
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
