import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/service/file_picker_service.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/documents/data/datasources/bank_details_service.dart';
import 'package:goapp/features/documents/data/repositories/bank_details_repository.dart';
import 'package:goapp/features/documents/data/repositories/bank_details_repository_impl.dart';

import '../cubit/bank_details_cubit.dart';
import '../cubit/bank_details_state.dart';
import 'view_bank_details_screen.dart';

class AddBankDetailsScreen extends StatelessWidget {
  const AddBankDetailsScreen({super.key, this.mode = DataMode.mock});

  final DataMode mode;

  @override
  Widget build(BuildContext context) {
    final BankDetailsRepository repository = BankDetailsRepositoryImpl(
      service: BankDetailsServiceImpl(mode: mode),
    );

    return BlocProvider<BankDetailsCubit>(
      create: (_) => BankDetailsCubit(
        repository: repository,
        filePickerService: sl<FilePickerService>(),
      ),
      child: const _AddBankDetailsView(),
    );
  }
}

class _AddBankDetailsView extends StatelessWidget {
  const _AddBankDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        title: 'Bank Details',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: BlocConsumer<BankDetailsCubit, BankDetailsState>(
          listener: (context, state) {
            final msg = state.errorMessage;
            if (msg != null && msg.trim().isNotEmpty) {
              SnackBarUtils.showError(context, msg.trim());
            }
            final details = state.details;
            if (state.status == BankDetailsStatus.success && details != null) {
              SnackBarUtils.show(context, 'Bank Details Added Successfully');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => ViewBankDetailsScreen(details: details),
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<BankDetailsCubit>();
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Bank Account',
                    child: Column(
                      children: [
                        _Field(
                          label: 'Account Holder Name',
                          hint: 'Name as per bank records',
                          onChanged: cubit.updateAccountHolderName,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'Bank Name',
                          hint: 'HDFC Bank',
                          onChanged: cubit.updateBankName,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'Account Number',
                          hint: 'Enter account number',
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: cubit.updateAccountNumber,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'Confirm Account Number',
                          hint: 'Re-enter account number',
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: cubit.updateConfirmAccountNumber,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'IFSC Code',
                          hint: 'HDFC0001234',
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(11),
                            _UpperCaseFormatter(),
                          ],
                          onChanged: cubit.updateIfscCode,
                        ),
                        const SizedBox(height: 12),
                        _TypePicker(
                          value: state.type,
                          onChanged: (v) {
                            if (v == null) return;
                            cubit.updateType(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Bank Book (Passbook)',
                    child: Column(
                      children: [
                        _PreviewBox(filePath: state.bankBookPath),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ShadowButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.coolwhite,
                                  foregroundColor: AppColors.headingNavy,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: AppColors.gray.shade200,
                                    ),
                                  ),
                                ),
                                onPressed: cubit.pickBankBook,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file_rounded),
                                    SizedBox(width: 8),
                                    Text('Upload Passbook'),
                                  ],
                                ),
                              ),
                            ),
                            if (state.hasBankBook) ...[
                              const SizedBox(width: 10),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: state.isLoading
                                    ? null
                                    : cubit.removeBankBook,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ShadowButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: state.canSubmit ? cubit.submit : null,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.headingNavy,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value.trim().isEmpty ? 'savings' : value,
          items: const [
            DropdownMenuItem(value: 'savings', child: Text('Savings')),
            DropdownMenuItem(value: 'current', child: Text('Current')),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.headingNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 18,
                color: AppColors.headingNavy,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.filePath});

  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final hasLocal = filePath != null && filePath!.trim().isNotEmpty;
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.coolwhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: hasLocal
            ? Image.file(File(filePath!), fit: BoxFit.cover)
            : const _EmptyPreview(),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_upload_rounded,
            color: AppColors.gray.shade400,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            'No file selected',
            style: TextStyle(color: AppColors.gray.shade600),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

String resolveBankBookUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final uri = Uri.tryParse(raw.trim());
  if (uri != null && uri.hasScheme) return raw.trim();
  return ApiConfig.resolve(raw.trim()).toString();
}
