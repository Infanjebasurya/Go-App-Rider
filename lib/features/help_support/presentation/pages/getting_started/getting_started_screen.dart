import 'package:flutter/material.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/help_support/presentation/pages/getting_started/how_to_complete_an_order_screen.dart';
import 'package:goapp/features/help_support/presentation/pages/getting_started/how_to_earn_more_screen.dart';
import 'package:goapp/features/help_support/presentation/pages/getting_started/how_to_transfer_money_to_bank_account_screen.dart';
import 'package:goapp/features/help_support/presentation/pages/getting_started/issue_with_ongoing_order_screen.dart';
import 'package:goapp/features/help_support/presentation/widgets/help_support_common_widgets.dart';

class GettingStartedScreen extends StatelessWidget {
  const GettingStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _GettingStartedItem.items;

    void openComingSoon(String title) {
      SnackBarUtils.show(context, '$title coming soon');
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Getting Started',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: const HelpSupportAppBarBottomDivider(),
      ),
      bottomNavigationBar: const HelpTicketTrackingFooter(),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const HelpSupportThinDivider(),
        itemBuilder: (context, index) {
          final item = items[index];
          return HelpSupportChevronListItem(
            title: item.title,
            onTap: () {
              if (item.title == 'How to complete an order') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HowToCompleteAnOrderScreen(),
                  ),
                );
                return;
              }
              if (item.title == 'How to transfer money to your bank account') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const HowToTransferMoneyToBankAccountScreen(),
                  ),
                );
                return;
              }
              if (item.title == 'How to earn more') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HowToEarnMoreScreen(),
                  ),
                );
                return;
              }
              if (item.title == 'Issue with an ongoing order') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const IssueWithAnOngoingOrderScreen(),
                  ),
                );
                return;
              }
              openComingSoon(item.title);
            },
          );
        },
      ),
    );
  }
}

class _GettingStartedItem {
  const _GettingStartedItem({required this.title});

  final String title;

  static const List<_GettingStartedItem> items = [
    _GettingStartedItem(title: 'How to complete an order'),
    _GettingStartedItem(title: 'How to transfer money to your bank account'),
    _GettingStartedItem(title: 'How to earn more'),
    _GettingStartedItem(title: 'Issue with an ongoing order'),
  ];
}
