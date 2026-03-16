import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/documents/presentation/widgets/document_capture_card.dart';

import '../cubit/document_upload_cubit.dart';
import '../model/document_upload_model.dart';
import 'document_camera_section.dart';

class BankAccountForm extends StatefulWidget {
  const BankAccountForm({super.key, required this.bankData});

  final BankAccountData bankData;

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bankCtrl;
  late final TextEditingController _accCtrl;
  late final TextEditingController _confirmCtrl;
  late final TextEditingController _ifscCtrl;
  late final FocusNode _nameFocus;
  late final FocusNode _bankFocus;
  late final FocusNode _accFocus;
  late final FocusNode _confirmFocus;
  late final FocusNode _ifscFocus;
  bool _obscureAccount = true;
  final GlobalKey _bankDocErrorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bankData.accountHolderName);
    _bankCtrl = TextEditingController(text: widget.bankData.bankName);
    _accCtrl = TextEditingController(text: widget.bankData.accountNumber);
    _confirmCtrl = TextEditingController(
      text: widget.bankData.confirmAccountNumber,
    );
    _ifscCtrl = TextEditingController(text: widget.bankData.ifscCode);
    _nameFocus = FocusNode();
    _bankFocus = FocusNode();
    _accFocus = FocusNode();
    _confirmFocus = FocusNode();
    _ifscFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _accCtrl.dispose();
    _confirmCtrl.dispose();
    _ifscCtrl.dispose();
    _nameFocus.dispose();
    _bankFocus.dispose();
    _accFocus.dispose();
    _confirmFocus.dispose();
    _ifscFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BankAccountForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadError =
        oldWidget.bankData.bankDocumentError != null &&
        oldWidget.bankData.bankDocumentError!.trim().isNotEmpty;
    final hasError =
        widget.bankData.bankDocumentError != null &&
        widget.bankData.bankDocumentError!.trim().isNotEmpty;

    if (!hadError && hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _bankDocErrorKey.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.bankData;
    final cubit = context.read<DocumentUploadCubit>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link Bank Account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.headingNavy,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Securely link your account for direct payouts',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            _BankField(
              label: 'Account Holder Name',
              hint: 'Enter full name as per bank records',
              controller: _nameCtrl,
              focusNode: _nameFocus,
              errorText: data.nameError,
              onChanged: (value) =>
                  cubit.updateAccountHolderName(value.toUpperCase()),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _bankFocus.requestFocus(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                _UpperCaseFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            _BankField(
              label: 'Bank Name',
              hint: 'Enter bank name',
              controller: _bankCtrl,
              focusNode: _bankFocus,
              errorText: data.bankNameError,
              onChanged: (value) => cubit.updateBankName(value.toUpperCase()),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _accFocus.requestFocus(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                _UpperCaseFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            _BankField(
              label: 'Account Number',
              hint: '•••• •••• •••• ••••',
              controller: _accCtrl,
              focusNode: _accFocus,
              errorText: data.accountNumberError,
              onChanged: (value) =>
                  cubit.updateAccountNumber(value.toUpperCase()),
              keyboardType: TextInputType.number,
              obscureText: _obscureAccount,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _confirmFocus.requestFocus(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                _UpperCaseFormatter(),
              ],
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscureAccount = !_obscureAccount),
                child: Icon(
                  _obscureAccount
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFF8FA0B0),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _BankField(
              label: 'Confirm Account Number',
              hint: 'Re-enter account number',
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              errorText: data.confirmAccountNumberError,
              onChanged: (value) =>
                  cubit.updateConfirmAccountNumber(value.toUpperCase()),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _ifscFocus.requestFocus(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                _UpperCaseFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            _BankField(
              label: 'IFSC Code',
              hint: 'HDFC0000000',
              controller: _ifscCtrl,
              focusNode: _ifscFocus,
              errorText: data.ifscError,
              onChanged: (v) {
                final value = v.toUpperCase();
                cubit.updateIfscCode(value);
                if (value.trim().length == 11) {
                  FocusScope.of(context).unfocus();
                }
              },
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(11),
                _UpperCaseFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            DocumentCaptureCard(
              label: 'Bank Book Front Page',
              captured:
                  data.bankDocumentPath != null &&
                  data.bankDocumentPath!.trim().isNotEmpty,
              filePath: data.bankDocumentPath,
              uploadType: data.bankDocumentType,
              showCardGuide: true,
              onTap: () => showBankDocumentSourceSheet(context),
              onRemove: () => cubit.removeBankDocument(),
            ),
            if (data.bankDocumentError != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                key: _bankDocErrorKey,
                width: double.infinity,
                child: Text(
                  data.bankDocumentError!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, color: AppColors.gold, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Security Guaranteed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingNavy,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your data is encrypted and managed according to\npremium banking standards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BankField extends StatelessWidget {
  const _BankField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? const Color(0xFFE53935) : const Color(0xFF8FA0B0),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.headingNavy,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
            suffixIcon: suffixIcon,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFE53935)
                    : const Color(0xFFD5DDE5),
                width: 1.2,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935), width: 1.2),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE53935)),
          ),
        ],
      ],
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
