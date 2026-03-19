import 'package:flutter/material.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/documents/data/models/save_bank_details_models.dart';

import 'add_bank_details_screen.dart' show resolveBankBookUrl;

class ViewBankDetailsScreen extends StatelessWidget {
  const ViewBankDetailsScreen({super.key, required this.details});

  final BankDetailsModel details;

  @override
  Widget build(BuildContext context) {
    final bankBookUrl = resolveBankBookUrl(details.bankBookUrl);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        title: 'Bank Details',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Account',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'ACCOUNT HOLDER',
                      value: details.accountHolder,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'BANK NAME', value: details.bankName),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'ACCOUNT NUMBER',
                      value: details.maskedAccountNumber,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'IFSC', value: details.ifsc),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'TYPE', value: details.type),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headingNavy,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(),
                        _StatusBadge(status: details.status),
                      ],
                    ),
                  ],
                ),
              ),
              if (bankBookUrl.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Passbook',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      bankBookUrl,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 170,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 170,
                          child: Center(child: Text('Failed to load image')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray.shade600,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.headingNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    Color bg;
    Color fg = AppColors.headingNavy;
    switch (normalized) {
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'pending' : normalized,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
