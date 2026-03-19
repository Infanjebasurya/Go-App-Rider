import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/help_support/presentation/cubit/help_cubit.dart';
import 'package:goapp/features/help_support/presentation/pages/nearby_demand_location/nearby_demand_location_screen.dart';
import 'package:goapp/features/help_support/presentation/pages/earnings/earnings_help_screen.dart';
import 'package:goapp/features/help_support/presentation/cubit/earnings_help_cubit.dart';
import 'package:goapp/features/help_support/presentation/pages/emergency/emergency_screen.dart';
import 'package:goapp/features/help_support/presentation/routes/help_support_routes.dart';
import 'package:goapp/features/help_support/presentation/widgets/help_support_common_widgets.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/help_support/presentation/pages/account/new_account_screen.dart';
import 'package:goapp/features/help_support/presentation/pages/app_issues/new_app_issue_screen.dart';
import 'package:goapp/features/help_support/presentation/pages/getting_started/getting_started_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelpCubit, HelpState>(
      builder: (context, state) {
        final cubit = context.read<HelpCubit>();
        final String query = state is HelpExploreState ? state.searchQuery : '';
        final items = _ExploreIssueItem.defaultItems;
        final filteredItems = query.trim().isEmpty
            ? items
            : items
                  .where(
                    (item) =>
                        item.title.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList(growable: false);

        void openComingSoon(String title) {
          SnackBarUtils.show(context, '$title coming soon');
        }

        void openIssue(_ExploreIssueItem item) {
          if (item.title == 'Nearby Demand Locations') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(
                  name: HelpSupportRoutes.nearbyDemandLocation,
                ),
                builder: (_) => const NearbyDemandLocationScreen(),
              ),
            );
            return;
          }

          if (item.title == 'Earnings') {
            ensureEarningsHelpDependenciesRegistered();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: HelpSupportRoutes.earnings),
                builder: (_) => BlocProvider(
                  create: (_) => sl<EarningsHelpCubit>(),
                  child: const EarningsHelpScreen(),
                ),
              ),
            );
            return;
          }

          if (item.title == 'Account') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: HelpSupportRoutes.account),
                builder: (_) => const NewAccountScreen(),
              ),
            );
            return;
          }

          if (item.title == 'App issues') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(
                  name: HelpSupportRoutes.appIssues,
                ),
                builder: (_) => const NewAppIssueScreen(),
              ),
            );
            return;
          }

          if (item.title == 'Emergency') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(
                  name: HelpSupportRoutes.emergency,
                ),
                builder: (_) => const EmergencyScreen(),
              ),
            );
            return;
          }

          if (item.title == 'Getting Started') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(
                  name: HelpSupportRoutes.gettingStarted,
                ),
                builder: (_) => const GettingStartedScreen(),
              ),
            );
            return;
          }

          openComingSoon(item.title);
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
              'Explore all Issues',
              style: TextStyle(fontSize: 18),
            ),
            backgroundColor: AppColors.white,
            elevation: 0,
            bottom: const HelpSupportAppBarBottomDivider(),
          ),
          bottomNavigationBar: const HelpTicketTrackingFooter(),
          body: Column(
            children: [
              HelpSearchBar(onChanged: cubit.updateSearch),
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Text(
                          'No issues found. Try a different search.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 0,
                          thickness: 0.5,
                          color: AppColors.handleGray.withValues(alpha: 0.2),
                        ),
                        itemBuilder: (context, i) {
                          final item = filteredItems[i];
                          final bool isAccount = item.title == 'Account';
                          final bool isAppIssues = item.title == 'App issues';
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.handleGray.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: InkWell(
                                onTap: () => openIssue(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 22,
                                        color: AppColors.textBody,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textBody,
                                          ),
                                        ),
                                      ),
                                      if (isAccount)
                                        InkWell(
                                          key: const Key(
                                            'explore_issue_account_chevron',
                                          ),
                                          onTap: () => openIssue(item),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      else if (isAppIssues)
                                        InkWell(
                                          key: const Key(
                                            'explore_issue_app_issues_chevron',
                                          ),
                                          onTap: () => openIssue(item),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.textSecondary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _ExploreIssueItem {
  const _ExploreIssueItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  static const List<_ExploreIssueItem> defaultItems = <_ExploreIssueItem>[
    _ExploreIssueItem(
      icon: Icons.location_on_outlined,
      title: 'Nearby Demand Locations',
    ),
    _ExploreIssueItem(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Earnings',
    ),
    _ExploreIssueItem(icon: Icons.settings_outlined, title: 'Account'),
    _ExploreIssueItem(icon: Icons.phone_android_outlined, title: 'App issues'),
    _ExploreIssueItem(icon: Icons.warning_amber_rounded, title: 'Emergency'),
    _ExploreIssueItem(
      icon: Icons.shield_outlined,
      title: 'Accidental Insurance',
    ),
    _ExploreIssueItem(icon: Icons.bolt_outlined, title: 'Getting Started'),
  ];
}
