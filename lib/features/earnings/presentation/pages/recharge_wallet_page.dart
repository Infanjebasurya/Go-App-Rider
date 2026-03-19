import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/earnings/presentation/cubit/earnings_cubit.dart';
import 'package:goapp/features/earnings/presentation/cubit/earnings_state.dart';
import 'package:goapp/features/earnings/presentation/pages/recharge_success_page.dart';
import 'package:goapp/core/widgets/keyboard_aware_bottom.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/core/widgets/shadow_button.dart';

class RechargeWalletPage extends StatelessWidget {
  const RechargeWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    return BlocBuilder<EarningsCubit, EarningsState>(
      builder: (context, state) {
        amountController.value = TextEditingValue(
          text: state.rechargeAmount,
          selection: TextSelection.collapsed(
            offset: state.rechargeAmount.length,
          ),
        );
        return Scaffold(
          backgroundColor: AppColors.surfaceF5,
          appBar: AppAppBar(
            backgroundColor: AppColors.surfaceF5,
            elevation: 0,
            title: const Text('Recharge Wallet'),
            centerTitle: true,
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 20),
                      const Text(
                        'ENTER AMOUNT',
                        style: TextStyle(
                          color: AppColors.neutral666,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.strokeLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              '\u20B9',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IntrinsicWidth(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                onChanged: context
                                    .read<EarningsCubit>()
                                    .setRechargeAmount,
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _QuickAddChip(amount: 500, selected: false),
                          _QuickAddChip(amount: 1000, selected: true),
                          _QuickAddChip(amount: 2000, selected: false),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PAYMENT METHOD',
                          style: TextStyle(
                            color: AppColors.neutral666,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PaymentMethodTile(
                        icon: Icons.qr_code_scanner,
                        title: 'UPI Payments',
                        subtitle: 'Google Pay, PhonePe, etc.',
                        value: 'UPI Payments',
                        selected: state.selectedPaymentMethod == 'UPI Payments',
                      ),
                      const SizedBox(height: 16),
                      _PaymentMethodTile(
                        icon: Icons.account_balance,
                        title: 'Net Banking',
                        subtitle: 'All major banks supported',
                        value: 'Net Banking',
                        selected: state.selectedPaymentMethod == 'Net Banking',
                      ),
                      const SizedBox(height: 16),
                      _PaymentMethodTile(
                        icon: Icons.credit_card,
                        title: 'Credit / Debit Card',
                        subtitle: 'Visa, Mastercard, RuPay',
                        value: 'Credit / Debit Card',
                        selected:
                            state.selectedPaymentMethod ==
                            'Credit / Debit Card',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: KeyboardAwareBottom(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ShadowButton(
                onPressed: () async {
                  final bool ok = await context
                      .read<EarningsCubit>()
                      .rechargeWallet();
                  if (!context.mounted) return;
                  if (!ok) {
                    SnackBarUtils.showError(
                      context,
                      'Enter a valid amount to recharge',
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          RechargeSuccessPage(amount: state.rechargeAmount),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Proceed to Pay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({required this.amount, required this.selected});

  final int amount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<EarningsCubit>().addRechargeAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.earningsAccentSoft : AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.strokeLight,
          ),
        ),
        child: Text(
          '+ \u20B9$amount',
          style: TextStyle(
            color: selected ? AppColors.emerald : AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<EarningsCubit>().selectPaymentMethod(value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : Border.all(color: AppColors.transparent),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.earningsAccentSoft
                    : AppColors.surfaceF5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.emerald, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral666,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.emerald : AppColors.neutralCCC,
                  width: selected ? 6 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
